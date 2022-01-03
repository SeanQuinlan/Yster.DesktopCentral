#Requires -Modules @{ModuleName='InvokeBuild';ModuleVersion='5.8.8'}
#Requires -Modules @{ModuleName='PowerShellGet';ModuleVersion='2.2.5'}
#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.3.1'}
#Requires -Modules @{ModuleName='ModuleBuilder';ModuleVersion='2.0.0'}

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Development', 'Release')]
    [string]
    $Configuration = 'Development'
)

$Script:IsAppveyor = $null -ne $env:APPVEYOR
$Script:ModuleName = Get-Item -Path $BuildRoot | Select-Object -ExpandProperty Name
Get-Module -Name $ModuleName | Remove-Module -Force

task Clean {
    Remove-Item -Path ".\Bin" -Recurse -Force -ErrorAction SilentlyContinue
}

task TestCode {
    Write-Build Yellow "`n`nTesting dev code before build"
    $PesterConfiguration = New-PesterConfiguration
    $PesterConfiguration.Run.Path = "$PSScriptRoot\Test"
    $PesterConfiguration.Output.Verbosity = 'None'
    $PesterConfiguration.Run.PassThru = $true
    $PesterConfiguration.Filter.Tag = 'Unit'
    $TestResult = Invoke-Pester -Configuration $PesterConfiguration
    if ($TestResult.FailedCount -gt 0) {
        Write-Warning -Message "Failing Tests:"
        $TestResult.TestResult.Where{$_.Result -eq 'Failed'} | ForEach-Object -Process {
            Write-Warning -Message $_.Name
            Write-Verbose -Message $_.FailureMessage -Verbose
        }
        throw 'Tests failed'
    }
}

task CompilePSM {
    Write-Build Yellow "`n`nCompiling all code into single psm1"
    $BuildParams = @{}
    $ModuleDefinition = Import-PowerShellDataFile -Path "$BuildRoot\Source\*.psd1"
    $BuildParams['SemVer'] = $ModuleDefinition.ModuleVersion
    Push-Location -Path "$BuildRoot\Source" -StackName 'InvokeBuildTask'
    $Script:CompileResult = Build-Module @BuildParams -Passthru
    Get-ChildItem -Path "$BuildRoot\license*" | Copy-Item -Destination $Script:CompileResult.ModuleBase
    Pop-Location -StackName 'InvokeBuildTask'
}

task MakeHelp -if (Test-Path -Path "$PSScriptRoot\Docs") {

}

task TestBuild {
    Write-Build Yellow "`n`nTesting compiled module"
    $PesterConfiguration = New-PesterConfiguration
    $PesterConfiguration.Run.Path = "$PSScriptRoot\Test"
    $PesterConfiguration.Output.Verbosity = 'None'
    $PesterConfiguration.Run.PassThru = $true
    $TestResult = Invoke-Pester -Configuration $PesterConfiguration

    if ($TestResult.FailedCount -gt 0) {
        Write-Warning -Message "Failing Tests:"
        $TestResult.TestResult.Where{$_.Result -eq 'Failed'} | ForEach-Object -Process {
            Write-Warning -Message $_.Name
            Write-Verbose -Message $_.FailureMessage -Verbose
        }
        throw 'Tests failed'
    }
}

task PublishModule -if ($Configuration -eq 'Release') {
    Write-Build Yellow "`n`nPublishing module to PSGallery"
    try {
        $Parameters = @{
            Path        = $Script:CompileResult.ModuleBase
            NuGetApiKey = $env:NugetApiKey
            ErrorAction = 'Stop'
            Verbose     = $true
        }
        Publish-Module @Parameters
    } catch {
        throw $_
    }
}

task . Clean, TestCode, Build

task Build CompilePSM, MakeHelp, TestBuild, PublishModule
