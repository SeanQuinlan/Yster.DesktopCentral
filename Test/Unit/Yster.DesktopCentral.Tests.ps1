# Some helpful links:
# https://stackoverflow.com/questions/62497134/pester-5-0-2-beforeall-block-code-not-showing-up-in-describe-block
# https://vexx32.github.io/2018/12/20/Searching-PowerShell-Abstract-Syntax-Tree/
# https://pester.dev/docs/usage/discovery-and-run
# https://pester.dev/docs/usage/data-driven-tests#migrating-from-pester-v4

BeforeDiscovery {
    $Module_Root = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Source'
    $Module_Path = Get-ChildItem -Path $Module_Root -Filter 'Yster.DesktopCentral.psd1'
    $Module_Information = Import-Module -Name $Module_Path.PSPath -Force -ErrorAction 'Stop' -PassThru
    $Module_ExportedFunctions = $Module_Information.ExportedFunctions.Values.Name

    $TestCases = New-Object -TypeName System.Collections.Generic.List[Hashtable]
    $Module_ExportedFunctions | ForEach-Object {
        $TestCases.Add(@{FunctionName = $_})
    }

    $ShouldProcess_Verbs = @('Add', 'Disable', 'Enable', 'Install', 'Invoke', 'Set', 'Remove', 'Resume', 'Suspend', 'Uninstall', 'Update')
    $ShouldProcess_TestCases = $TestCases | Where-Object { $ShouldProcess_Verbs -contains ($_['FunctionName'].Split('-'))[0] }

    $Common_Required_Parameters = @(
        @{'ParameterName' = 'AuthToken'}
        @{'ParameterName' = 'HostName'}
    )
    $Common_Optional_Parameters = @(
        @{'ParameterName' = 'SkipCertificateCheck'}
    )
}

Describe 'Function Validation for: <FunctionName>' -Tags @('Module', 'Unit') -ForEach $TestCases {
    BeforeAll {
        $Function_Contents = Get-Content -Path function:$FunctionName
        $Function_AST = [System.Management.Automation.Language.Parser]::ParseInput($Function_Contents, [ref]$null, [ref]$null)
        $Function_Name_Declaration = '$Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name'

        # Functions that can't have an AuthToken parameter.
        $Non_AuthToken_Functions = @('Get-DCAPIToken')
        # Functions that can have an optional AuthToken parameter.
        $Non_Mandatory_AuthToken_Functions = @('Get-DCServerOptions')
    }

    Context 'Function Help' {
        It '<FunctionName> has Synopsis' {
            $Function_AST.GetHelpContent().Synopsis | Should -Not -BeNullOrEmpty
        }
        It '<FunctionName> has Description' {
            $Function_AST.GetHelpContent().Description | Should -Not -BeNullOrEmpty
        }
        It '<FunctionName> has at least 1 Code example' {
            $Function_AST.GetHelpContent().Examples.Count | Should -BeGreaterThan 0
        }
        # Insipired from: https://lazywinadmin.com/2016/08/powershellpester-make-sure-your-comment.html
        It '<FunctionName> has indented comment block' {
            $null = $Function_Contents -match '(?ms)\s+\<\#.*\>\#?'
            $Function_CommentsNotIndented = $matches[0].Split("`n") -notmatch '^[\t|\s{4}]'
            $Function_CommentsNotIndented.Count | Should -Be 0
        }
        # Inspired from: https://lazywinadmin.com/2016/08/powershellpester-make-sure-your.html
        It '<FunctionName> has parameters separated by blank lines' {
            $Function_ParamBlock_Text = $Function_AST.ParamBlock.Extent.Text.Split("`n").Trim()
            $Function_ParameterNames = $Function_AST.ParamBlock.Parameters.Name.VariablePath.UserPath
            $Function_ParameterBlocks = $Function_ParameterNames | Where-Object {
                $Function_AST.ParamBlock.Extent.Text -match ('\${0}.*,' -f $_) # Only match those with a comma after the parameter (ie. exclude the last parameter).
            }

            foreach ($ParameterName in $Function_ParameterBlocks) {
                # Select-String's LineNumber properties start from 1 since they are designed to be output to the console.
                # This is useful because it effectively gets the line "after" the match, which is the line we want to check is a blank line.
                $Function_Param_LineNumber = $Function_ParamBlock_Text | Select-String ('{0}.*,$' -f $ParameterName) | Select-Object -ExpandProperty LineNumber
                [String]::IsNullOrWhiteSpace($Function_ParamBlock_Text[$Function_Param_LineNumber]) | Should -Be $true
            }
        }
    }

    Context 'Function Parameters' {
        It '<FunctionName> has no global variables defined' {
            # Find all variables, including those in sub-functions (the $true at the end).
            $Function_Nodes = $Function_AST.FindAll({return ($args[0] -is [System.Management.Automation.Language.VariableExpressionAst])}, $true)
            $Function_Nodes | Where-Object { ($_.VariablePath.UserPath -match 'global') } | Should -Be $null
        }
    }

    Context 'Function Variables' {
        It '<FunctionName> has $Function_Name variable declaration' {
            # Only look for the $Function_Name variable declaration in the main function, not sub-functions.
            $Function_Nodes = $Function_AST.FindAll({return ($args[0] -is [System.Management.Automation.Language.VariableExpressionAst])}, $false)
            $Function_Nodes | Where-Object { ($_.VariablePath.UserPath -eq 'Function_Name') -and ($_.Parent.Extent.Text -eq $Function_Name_Declaration) } | Should -Be $true
        }
    }

    Context 'Required Parameters' {
        It ('<FunctionName> has required parameter: <ParameterName>') -Foreach $Common_Required_Parameters {
            if (($ParameterName -eq 'AuthToken') -and ($Non_AuthToken_Functions -contains $FunctionName)) {
                $Required_Parameter_Check = $Function_AST.ParamBlock.Parameters | Where-Object { $_.Name.Extent.Text -eq ('${0}' -f $ParameterName) }
                $Required_Parameter_Check | Should -BeNullOrEmpty
            } elseif (($ParameterName -eq 'AuthToken') -and ($Non_Mandatory_AuthToken_Functions -contains $FunctionName)) {
                $Required_Parameter_Check = $Function_AST.ParamBlock.Parameters | Where-Object { $_.Name.Extent.Text -eq ('${0}' -f $ParameterName) }
                $Required_Parameter_Check | Should -Not -BeNullOrEmpty
            } else {
                $Required_Parameter_Check = $Function_AST.ParamBlock.Parameters | Where-Object { ($_.Name.Extent.Text -eq ('${0}' -f $ParameterName)) -and ($_.Extent.Text -match 'Mandatory = \$true') }
                $Required_Parameter_Check | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Optional Parameters' {
        It ('<FunctionName> has optional parameter: <ParameterName>') -Foreach $Common_Optional_Parameters {
            $Optional_Parameter_Check = $Function_AST.ParamBlock.Parameters | Where-Object { $_.Name.Extent.Text -eq ('${0}' -f $ParameterName) }
            $Optional_Parameter_Check | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'ShouldProcess Validation for: <FunctionName>' -Tags @('Module', 'Unit') -ForEach $ShouldProcess_TestCases {
    BeforeAll {
        $Function_Contents = Get-Content -Path function:$FunctionName
        $Function_AST = [System.Management.Automation.Language.Parser]::ParseInput($Function_Contents, [ref]$null, [ref]$null)
        $ShouldProcess_Text = 'SupportsShouldProcess = $true'
    }

    # Inspired from: https://vexx32.github.io/2018/12/20/Searching-PowerShell-Abstract-Syntax-Tree/
    Context 'ShouldProcess Validation' {
        It '<FunctionName> has SupportsShouldProcess set to $true' {
            $Function_AST.ParamBlock.Attributes.NamedArguments | Where-Object { $_.ArgumentName -eq 'SupportsShouldProcess' -and ($_.Extent.Text -eq $ShouldProcess_Text) } | Should -Not -BeNullOrEmpty
        }
        It '<FunctionName> has $PSCmdlet.ShouldProcess line' {
            # Look for a $PSCmdlet.ShouldProcess line in the main function only (ignoring sub-functions).
            $Function_Nodes = $Function_AST.FindAll({return ($args[0] -is [System.Management.Automation.Language.VariableExpressionAst])}, $false)
            $Function_Nodes | Where-Object { ($_.VariablePath.UserPath -eq 'PSCmdlet') -and ($_.Parent.Extent.Text -match '\$PSCmdlet.ShouldProcess')} | Should -Not -BeNullOrEmpty
        }
    }
}
