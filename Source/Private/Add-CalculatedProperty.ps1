function Add-CalculatedProperty {
    <#
    .SYNOPSIS
        Adds certain calculated properties to make the output more useful.
    .DESCRIPTION
        Adds some additional properties to the output to reduce the amount of additional processing that needs to be done after getting the result.

        For example: Looks for all numeric time properties and adds a corresponding property with a DateTime value.

        This is an internal function and not meant to be called directly.
    .EXAMPLE
        $REST_Response.message_response.computers | Add-CalculatedProperty
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
    }

    process {
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $InputObject = $_
        }

        # Time Properties
        $Time_Property_Regex = '_on$|_time$'
        $InputObject_Properties = $InputObject.PSObject.Properties
        foreach ($InputObject_PropertyName in $InputObject_Properties.Name) {
            if ($InputObject.$InputObject_PropertyName -is [PSCustomObject]) {
                Write-Verbose ('{0}|Recursing into same function' -f $Function_Name)
                Add-TimeProperty -InputObject $InputObject.$InputObject_PropertyName
            } elseif ($InputObject_PropertyName -match $Time_Property_Regex) {
                Write-Verbose ('{0}|Adding Calculated Time property for: {1}' -f $Function_Name, $InputObject_PropertyName)
                $Add_Property_Name = $InputObject_PropertyName -split '_' | ForEach-Object {
                    (Get-Culture).TextInfo.ToTitleCase($_)
                }
                $InputObject | Add-Member -MemberType 'NoteProperty' -Name ($Add_Property_Name -join '') -Value (Get-DCTime -DCTime $InputObject.$InputObject_PropertyName)
            }
        }

        # Group Properties
        if ($InputObject.'groupCategory') {
            $InputObject | Add-Member -MemberType 'NoteProperty' -Name 'groupCategoryName' -Value ($Group_Categories_Mapping.GetEnumerator() | Where-Object { $_.Value -eq $InputObject.'groupCategory' }).Name
        }
        if ($InputObject.'groupType') {
            $InputObject | Add-Member -MemberType 'NoteProperty' -Name 'groupTypeName' -Value ($Group_Types_Mapping.GetEnumerator() | Where-Object { $_.Value -eq $InputObject.'groupType' }).Name
        }

        # OS Properties
        if ($InputObject.'osPlatform') {
            $InputObject | Add-Member -MemberType 'NoteProperty' -Name 'OSPlatformName' -Value ($OSPlatform_Mapping.GetEnumerator() | Where-Object { $_.Value -eq $InputObject.'osPlatform' }).Name
        }

        # Return the modified object
        $InputObject
    }
}
