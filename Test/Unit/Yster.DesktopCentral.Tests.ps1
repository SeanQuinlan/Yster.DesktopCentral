# Some helpful links:
# https://stackoverflow.com/questions/62497134/pester-5-0-2-beforeall-block-code-not-showing-up-in-describe-block
# https://vexx32.github.io/2018/12/20/Searching-PowerShell-Abstract-Syntax-Tree/

Describe 'Function Validation' -Tags 'Module', 'Unit' {
    $Module_Root = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Source'
    $Module_Path = Get-ChildItem -Path $Module_Root -Filter 'Yster.DesktopCentral.psd1'
    $global:Module_Information = Import-Module -Name $Module_Path.PSPath -Force -ErrorAction 'Stop' -PassThru
    $Module_ExportedFunctions = $Module_Information.ExportedFunctions.Values.Name

    $TestCases = New-Object -TypeName System.Collections.Generic.List[Hashtable]
    $Module_ExportedFunctions | ForEach-Object {
        [void]$TestCases.Add(@{FunctionName = $_})
    }
    $ShouldProcess_Verbs = @('Add', 'Disable', 'Enable', 'Install', 'Invoke', 'Set', 'Remove', 'Resume', 'Suspend', 'Uninstall', 'Update')
    $ShouldProcess_TestCases = $TestCases | Where-Object { $ShouldProcess_Verbs -contains ($_['FunctionName'].Split('-'))[0] }

    BeforeEach {
        $Function_Contents = Get-Content -Path function:$FunctionName
        $Function_AST = [System.Management.Automation.Language.Parser]::ParseInput($Function_Contents, [ref]$null, [ref]$null)
    }

    Context 'Function Help - has Synopsis' {
        It '<FunctionName> has Synopsis' -TestCases $TestCases {
            $Function_AST.GetHelpContent().Synopsis | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Function Help - has Description' {
        It '<FunctionName> has Description' -TestCases $TestCases {
            $Function_AST.GetHelpContent().Description | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Function Help - has at least 1 Code example' {
        It '<FunctionName> has at least 1 Code example' -TestCases $TestCases {
            $Function_AST.GetHelpContent().Examples.Count | Should -BeGreaterThan 0
        }
    }

    # Insipired from: https://lazywinadmin.com/2016/08/powershellpester-make-sure-your-comment.html
    Context 'Function Help - Comment block is indented' {
        It '<FunctionName> has indented comment block' -TestCases $TestCases {
            $null = $Function_Contents -match '(?ms)\s+\<\#.*\>\#?'
            $Function_CommentsNotIndented = $matches[0].Split("`n") -notmatch '^[\t|\s{4}]'
            $Function_CommentsNotIndented.Count | Should -Be 0
        }
    }

    # Inspired from: https://lazywinadmin.com/2016/08/powershellpester-make-sure-your.html
    Context 'Function has parameters separated by blank line' {
        It '<FunctionName> parameters separated by blank lines' -TestCases $TestCases {
            $Function_ParamBlock = $Function_AST.ParamBlock.Extent.Text.Split("`n").Trim()
            $Function_ParameterNames = $Function_AST.ParamBlock.Parameters.Name.VariablePath.UserPath
            $Function_ParameterBlocks = $Function_ParameterNames | Where-Object {
                $Function_AST.ParamBlock.Extent.Text -match ('\${0}.*,' -f $_) # Only match those with a comma after the parameter (ie. exclude the last parameter).
            }

            foreach ($ParameterName in $Function_ParameterBlocks) {
                # Select-String's LineNumber properties start from 1 since they are designed to be output to the console.
                # This is useful because it effectively gets the line "after" the match, which is the line we want to check is a blank line.
                $Function_Param_LineNumber = $Function_ParamBlock | Select-String ('{0}.*,$' -f $ParameterName) | Select-Object -ExpandProperty LineNumber
                [String]::IsNullOrWhiteSpace($Function_ParamBlock[$Function_Param_LineNumber]) | Should -Be $true
            }
        }
    }

    Context 'Function variables' {
        It '<FunctionName> has no global variables defined' -TestCases $TestCases {
            # Find all variables, including those in sub-functions (the $true at the end).
            $Function_Nodes = $Function_AST.FindAll({return ($args[0] -is [System.Management.Automation.Language.VariableExpressionAst])}, $true)
            $Function_Nodes | Where-Object { ($_.VariablePath.UserPath -match 'global') } | Should -Be $null
        }
        It '<FunctionName> has Function_Name parameter declaration' -TestCases $TestCases {
            $Function_Name_Declaration = '$Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name'
            # Only look for the above variable declaration in the main function, not sub-functions.
            $Function_Nodes = $Function_AST.FindAll({return ($args[0] -is [System.Management.Automation.Language.VariableExpressionAst])}, $false)
            $Function_Nodes | Where-Object { ($_.VariablePath.UserPath -eq 'Function_Name') -and ($_.Parent.Extent.Text -eq $Function_Name_Declaration) } | Should -Be $true
        }
    }

    # Inspired from: https://vexx32.github.io/2018/12/20/Searching-PowerShell-Abstract-Syntax-Tree/
    Context 'Function implements ShouldProcess' {
        It '<FunctionName> has SupportsShouldProcess set to $true' -TestCases $ShouldProcess_TestCases {
            $ShouldProcess_Text = 'SupportsShouldProcess = $true'
            # Get the first param block in the main function, and do not recurse into sub-functions.
            $Param_Block = $Function_AST.Find({return ($args[0] -is [System.Management.Automation.Language.ParamBlockAst])}, $false)
            $Param_Block.Attributes.NamedArguments | Where-Object { $_.ArgumentName -eq 'SupportsShouldProcess' -and ($_.Extent.Text -eq $ShouldProcess_Text) } | Should -Not -BeNullOrEmpty
        }

        It '<FunctionName> has $PSCmdlet.ShouldProcess line' -TestCases $ShouldProcess_TestCases {
            # Look for a $PSCmdlet.ShouldProcess line in the main function only (ignoring sub-functions).
            $Function_Nodes = $Function_AST.FindAll({return ($args[0] -is [System.Management.Automation.Language.VariableExpressionAst])}, $false)
            $Function_Nodes | Where-Object { ($_.VariablePath.UserPath -eq 'PSCmdlet') -and ($_.Parent.Extent.Text -match '\$PSCmdlet.ShouldProcess')} | Should -Not -BeNullOrEmpty
        }
    }
}
