function New-DefaultErrorRecord {
    <#
    .SYNOPSIS
        Create an ErrorRecord object using an exception object.
    .DESCRIPTION
        A simple wrapper function to standardise the default terminating error that is found in the main catch block of every function.
    .EXAMPLE
        New-DefaultErrorRecord -InputObject $_
    #>

    [CmdletBinding()]
    param(
        # The exception object that will be used to create the ErrorRecord.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    $Default_ErrorRecord_Parameters = @{
        'Exception'      = $InputObject.Exception.GetType().FullName
        'ID'             = $InputObject.FullyQualifiedErrorId
        'Category'       = $InputObject.CategoryInfo.Category
        'TargetObject'   = $InputObject.TargetObject
        'Message'        = $InputObject.Exception.Message
        'InnerException' = $InputObject.Exception
    }
    New-ErrorRecord @Default_ErrorRecord_Parameters
}
