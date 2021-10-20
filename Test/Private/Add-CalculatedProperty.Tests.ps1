BeforeAll {
    $Module_Root = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Source'
    $Files_To_Load = @('Shared_Variables.ps1', 'Add-CalculatedProperty.ps1')
    $Files_To_Load | ForEach-Object {
        . (Get-ChildItem -Recurse -Path $Module_Root -Filter $_).PSPath
    }
}

Describe 'Add-CalculatedProperty' -Tags 'Unit' {
    BeforeEach {
        $TestObject = [pscustomobject]@{
            'test_time'         = 1634566990000
            'groupCategory'     = 5
            'groupType'         = 1
            'osPlatform'        = 1
            'collection_status' = 5
        }
        $TestResult = $TestObject | Add-CalculatedProperty
    }

    It 'Adds the correct time property' {
        $UtcTime = New-Object -TypeName DateTime 2021, 10, 18, 14, 23, 10, ([DateTimeKind]::Utc)
        $CompareTime = $UtcTime.ToLocalTime()
        $TestResult.TestTime | Should -Be $CompareTime
    }
    It 'Adds the correct groupCategoryName property' {
        $CompareGroupCategory = 'StaticUnique'
        $TestResult.groupCategoryName | Should -Be $CompareGroupCategory
    }
    It 'Adds the correct groupTypeName property' {
        $CompareGroupType = 'Computer'
        $TestResult.groupTypeName | Should -Be $CompareGroupType
    }
    It 'Adds the correct OSPlatform property' {
        $CompareOSPlatform = 'Windows'
        $TestResult.OSPlatformName | Should -Be $CompareOSPlatform
    }
    It 'Adds the correct CollectionStatus property' {
        $CompareCollectionStatus = 'Suspended'
        $TestResult.CollectionStatus | Should -Be $CompareCollectionStatus
    }
}
