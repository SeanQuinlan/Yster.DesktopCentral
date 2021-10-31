function Add-Filters {
    <#
    .SYNOPSIS
        Appends the filter to the BaseURL supplied.
    .DESCRIPTION
        Looks through the BoundParameters hashtable and adds any filters that are provided.

        Returns the BaseURL with the filters appended.
    .EXAMPLE
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'patch/allsystems'
    .NOTES
    #>

    [CmdletBinding()]
    param(
        # The base URL to use.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $BaseURL,

        # A hashtable of the PSBoundParameters that were passed from the calling function.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $BoundParameters
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        if ($_.Value -is [Hashtable]) {
            Write-Verbose ("{0}|Arguments: {1}:`n{2}" -f $Function_Name, $_.Key, ($_.Value | Format-Table -AutoSize | Out-String).Trim())
        } else {
            Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' '))
        }
    }

    $Filters = New-Object -TypeName 'System.Collections.Generic.List[String]'
    if ($BoundParameters.ContainsKey('ApprovalStatus')) {
        $Filters.Add('approvalstatusfilter={0}' -f $Approval_Status_Mapping[$BoundParameters['ApprovalStatus']])
    }
    if ($BoundParameters.ContainsKey('BranchOffice')) {
        $Filters.Add('branchofficefilter={0}' -f ($BoundParameters['BranchOffice'] -replace '\s', '+'))
    }
    if ($BoundParameters.ContainsKey('BulletinID')) {
        $Filters.Add('bulletinid={0}' -f $BoundParameters['BulletinID'])
    }
    if ($BoundParameters.ContainsKey('ConfigStatus')) {
        $Filters.Add('configstatusfilter={0}' -f $BoundParameters['ConfigStatus'])
    }
    if ($BoundParameters.ContainsKey('CustomGroup')) {
        $Filters.Add('customgroupfilter={0}' -f ($BoundParameters['CustomGroup'] -replace '\s', '+'))
    }
    if ($BoundParameters.ContainsKey('Domain')) {
        $Filters.Add('domainfilter={0}' -f $BoundParameters['Domain'])
    }
    if ($BoundParameters.ContainsKey('GroupCategory')) {
        $Filters.Add('groupCategories={0}' -f $GroupCategories_Mapping[$BoundParameters['GroupCategory']])
    }
    if ($BoundParameters.ContainsKey('GroupID')) {
        $Filters.Add('cgResourceIds={0}' -f ($BoundParameters['GroupID'] -join ','))
    }
    if ($BoundParameters.ContainsKey('GroupType')) {
        $Filters.Add('groupTypes={0}' -f $GroupTypes_Mapping[$BoundParameters['GroupType']])
    }
    if ($BoundParameters.ContainsKey('Health')) {
        $Filters.Add('healthfilter={0}' -f $Health_Mapping[$BoundParameters['Health']])
    }
    if ($BoundParameters.ContainsKey('InstallStatus')) {
        $Filters.Add('installstatusfilter={0}' -f $InstallStatus_Mapping[$BoundParameters['InstallStatus']])
    }
    if ($BoundParameters.ContainsKey('LiveStatus')) {
        $Filters.Add('livestatusfilter={0}' -f $LiveStatus_Mapping[$BoundParameters['LiveStatus']])
    }
    if ($BoundParameters.ContainsKey('Page')) {
        $Filters.Add('page={0}' -f $BoundParameters['Page'])
    }
    if ($BoundParameters.ContainsKey('PatchID')) {
        $Filters.Add('patchid={0}' -f $BoundParameters['PatchID'])
    }
    if ($BoundParameters.ContainsKey('PatchStatus')) {
        $Filters.Add('patchstatusfilter={0}' -f $Patch_Status_Mapping[$BoundParameters['PatchStatus']])
    }
    if ($BoundParameters.ContainsKey('Platform')) {
        $Filters.Add('platformfilter={0}' -f $BoundParameters['Platform'])
    }
    if ($BoundParameters.ContainsKey('ResourceID')) {
        $Filters.Add('resid={0}' -f $BoundParameters['ResourceID'])
    }
    if ($BoundParameters.ContainsKey('ResourceIDFilter')) {
        $Filters.Add('residfilter={0}' -f $BoundParameters['ResourceIDFilter'])
    }
    if ($BoundParameters.ContainsKey('ResultSize')) {
        $Filters.Add('pagelimit={0}' -f $BoundParameters['ResultSize'])
    }
    if ($BoundParameters.ContainsKey('ScanStatus')) {
        $Filters.Add('scanstatusfilter={0}' -f $ScanStatus_Mapping[$BoundParameters['ScanStatus']])
    }
    if ($BoundParameters.ContainsKey('SearchField')) {
        $Filters.Add('searchtype={0}' -f $BoundParameters['SearchField'])
        $Filters.Add('searchcolumn={0}' -f $BoundParameters['SearchField'])
    }
    if ($BoundParameters.ContainsKey('SearchValue')) {
        $Filters.Add('searchvalue={0}' -f $BoundParameters['SearchValue'])
    }
    if ($BoundParameters.ContainsKey('Severity')) {
        $Filters.Add('severityfilter={0}' -f $Severity_Mapping[$BoundParameters['Severity']])
    }
    if ($BoundParameters.ContainsKey('TaskName')) {
        $Filters.Add('taskname={0}' -f $BoundParameters['TaskName'])
    }

    if ($Filters.Count) {
        $BaseURL += '?{0}' -f ($Filters -join '&')
    }
    $BaseURL
}
