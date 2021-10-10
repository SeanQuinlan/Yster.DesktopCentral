# Some helpful links:
# https://stackoverflow.com/questions/62497134/pester-5-0-2-beforeall-block-code-not-showing-up-in-describe-block

Describe 'Function Validation' -Tags 'Module', 'Unit' {
    $Module_Root = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Source'
    $Module_Path = Get-ChildItem -Path $Module_Root -Filter 'Yster.DesktopCentral.psd1'
    $Module_Information = Import-Module -Name $Module_Path.PSPath -Force -ErrorAction 'Stop' -PassThru
    $Module_ExportedFunctions = $Module_Information.ExportedFunctions.Values.Name

    [System.Collections.ArrayList]$TestCases = @()
    $Module_ExportedFunctions | ForEach-Object {
        [void]$TestCases.Add(@{FunctionName = $_})
    }

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
            $Function_CommentsNotIndented.Count | Should -Be 0        }
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
        # It '<FunctionName> has no global variables defined' -TestCases $TestCases {
        #     $Function_Nodes = $Function_AST.FindAll( { $true }, $false) | Where-Object { $_.GetType().Name -eq 'VariableExpressionAst' }
        #     $Function_Nodes | Where-Object { ($_.VariablePath.UserPath -match 'global') } | Should -Be $null
        # }
        It '<FunctionName> has Function_Name parameter declaration' -TestCases $TestCases {
            $Function_Name_Declaration = '$Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name'
            $Function_Nodes = $Function_AST.FindAll( { $true }, $false) | Where-Object { $_.GetType().Name -eq 'VariableExpressionAst' }
            $Function_Nodes | Where-Object { ($_.VariablePath.UserPath -eq 'Function_Name') -and ($_.Parent.Extent.Text -eq $Function_Name_Declaration) } | Should -Be $true
        }
    }

}
