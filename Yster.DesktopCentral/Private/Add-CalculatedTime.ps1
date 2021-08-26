function Add-CalculatedTime {
    <#
    .SYNOPSIS
        Adds DateTime properties for all numeric time properties.
    .DESCRIPTION
        Looks for all numeric time properties and adds a corresponding property with a DateTime value.

        This is an internal function and not meant to be called directly.
    .EXAMPLE
        $REST_Response.message_response.computers | Add-CalculatedTime
    .NOTES

    #>

    [CmdletBinding()]
    param(
        # The input object.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]
        $InputObject
    )

    begin {
        $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

        function Get-DCTime {
            param(
                # No validation on this parameter as sometimes null or empty strings are passed in.
                [Parameter(Mandatory = $false)]
                [String]
                $DCTime
            )

            if (($DCTime -match '^(\-1|\-\-)$') -or ([String]::IsNullOrEmpty($DCTime))) { return }

            $Time_In_UTC = (Get-Date 01.01.1970) + ([System.TimeSpan]::FromSeconds(($DCTime / 1000)))
            $Time_In_Local_TimeZone = [System.TimeZoneInfo]::ConvertTimeFromUtc($Time_In_UTC, $TimeZone_Info)
            Get-Date -Date $Time_In_Local_TimeZone
        }

        function Add-TimeProperty {
            param(
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [Object]
                $BaseObject
            )

            $Time_Property_Regex = '_on$|_time$'

            $BaseObject_Properties = $BaseObject.PSObject.Properties
            foreach ($BaseObject_PropertyName in $BaseObject_Properties.Name) {
                if ($BaseObject.$BaseObject_PropertyName -is [PSCustomObject]) {
                    Write-Verbose ('{0}|Recursing into same function' -f $Function_Name)
                    Add-TimeProperty -BaseObject $BaseObject.$BaseObject_PropertyName
                } elseif ($BaseObject_PropertyName -match $Time_Property_Regex) {
                    Write-Verbose ('{0}|Adding Calculated Time property for: {1}' -f $Function_Name, $BaseObject_PropertyName)
                    $Add_Property_Name = $BaseObject_PropertyName -split '_' | ForEach-Object {
                        (Get-Culture).TextInfo.ToTitleCase($_)
                    }
                    $BaseObject | Add-Member -MemberType 'NoteProperty' -Name ($Add_Property_Name -join '') -Value (Get-DCTime -DCTime $BaseObject.$BaseObject_PropertyName)
                }
            }
        }
    }

    process {
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $InputObject = $_
        }

        Add-TimeProperty -BaseObject $InputObject
        $InputObject
    }
}
