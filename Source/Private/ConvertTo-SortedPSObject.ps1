function ConvertTo-SortedPSObject {
    <#
    .SYNOPSIS
        Sorts a Hashtable or PSObject alphabetically by properties and returns the result as a PSCustomObject.
    .DESCRIPTION
        Takes an input object of type Hashtable or PSObject, and sorts it aphabetically by Property Name. A PSCustomObject with the sorted properties is returned.
    .EXAMPLE
        $SortedResults = ConvertTo-SortedPSObject -InputObject $ResultsObject
    .EXAMPLE
        $ResultsObject | ConvertTo-SortedObject
    .NOTES
        The method of converting to a hashtable and then using that as the input for a new PSObject was fastest in my testing.

        Faster than using Add-Member, and faster than using the $Object.PSObject.Properties.Add($PSNoteProperty) method I have seen used in other places before.
    #>

    [CmdletBinding()]
    param(
        # The input object.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $InputObject
    )

    begin {
        $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }
    }

    process {
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $InputObject = $_
        }

        if ($InputObject -is [Hashtable]) {
            Write-Verbose ('{0}|Hashtable type' -f $Function_Name)
            $Input_Object_Properties = $InputObject.GetEnumerator()
        } elseif ($InputObject -is [PSObject]) {
            Write-Verbose ('{0}|PSObject type' -f $Function_Name)
            $Input_Object_Properties = $InputObject.PSObject.Properties
        } else {
            Write-Error ('Unknown input object: {0}' -f $InputObject.GetType()) -ErrorAction 'Stop'
        }

        # Sort results and then add to a new hashtable, as PSObject requires a hashtable as Property. GetEnumerator() piped into Sort-Object changes the output to an array.
        $Input_Object_Sorted = [Ordered]@{}
        $Input_Object_Properties | Sort-Object -Property 'Name' | ForEach-Object {
            # Sort any sub-objects if required.
            if ($_.Value -is [Array]) {
                $Value = $_.Value | ConvertTo-SortedPSObject
            } else {
                $Value = $_.Value
            }
            $Input_Object_Sorted[$_.Name] = $Value
        }
        New-Object -TypeName 'System.Management.Automation.PSObject' -Property $Input_Object_Sorted
    }
}
