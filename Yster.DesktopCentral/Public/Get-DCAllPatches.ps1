function Get-DCAllPatches {
    <#
    .SYNOPSIS
        Gets a list of all patches applicable to your environment.
    .DESCRIPTION
        Provides a list of all patches that are available in the Patch Management interface.

        With no filters, it will display all applicable patches. This can be filtered down to just installed or just missing patches.
        Or the patches can be filtered by ID, BulletinID, Approval Status or Severity.
    .EXAMPLE
        Get-DCAllPatches -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -Domain 'YSTER' -PatchStatus Missing

        Displays just the missing patches for the YSTER domain.
    .NOTES
        https://www.manageengine.com/patch-management/api/all-patches-patch-management.html
    #>

    [CmdletBinding()]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The hostname of the Desktop Central server.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $HostName,

        # The port of the Desktop Central server.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Port = 8020,

        # The Domain to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,

        # The Branch Office to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $BranchOffice,

        # The Custom Group to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $CustomGroup,

        # The Platform to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Mac', 'Windows')]
        [String]
        $Platform,

        # The PatchID to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $PatchID,

        # The BulletinID to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $BulletinID,

        # The Patch Status to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Installed', 'Missing')]
        [String]
        $PatchStatus,

        # The Approval Status to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Approved', 'NotApproved')]
        [String]
        $ApprovalStatus,

        # The Severity to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Unrated', 'Low', 'Moderate', 'Important', 'Critical')]
        [String]
        $Severity
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    # branch office filters with spaces?

    # testing
    # -------
    # [x] domain
    # [ ] branch office
    # [ ] custom group
    # [o] platform - no difference if I use "mac", still same results as "windows" or nothing. Doesn't matter what I put into platformfilter
    # [x] patchid
    # [x] bulletinid
    # [ ] patchstatus - needs more testing - for missing, I got 4 out of 13, for installed I got an error
    # [ ] approvalstatus - needs more testing, got all 13 returned for approved, 0 for notapproved
    # [x] severity

    try {
        $API_Path = 'patch/allpatches'
        $Filters = New-Object -TypeName 'System.Collections.Generic.List[String]'
        if ($PSBoundParameters.ContainsKey('Domain')) {
            $Additional_Filter = 'domainfilter={0}' -f $Domain
            $Filters.Add($Additional_Filter)
        }
        if ($PSBoundParameters.ContainsKey('BranchOffice')) {
            $Additional_Filter = 'branchofficefilter={0}' -f $BranchOffice
            $Filters.Add($Additional_Filter)
        }
        if ($PSBoundParameters.ContainsKey('CustomGroup')) {
            $Additional_Filter = 'customgroupfilter={0}' -f $CustomGroup
            $Filters.Add($Additional_Filter)
        }
        if ($PSBoundParameters.ContainsKey('Platform')) {
            $Additional_Filter = 'platformfilter={0}' -f $Platform
            $Filters.Add($Additional_Filter)
        }
        if ($PSBoundParameters.ContainsKey('PatchID')) {
            $Additional_Filter = 'patchid={0}' -f $PatchID
            $Filters.Add($Additional_Filter)
        }
        if ($PSBoundParameters.ContainsKey('BulletinID')) {
            $Additional_Filter = 'bulletinid={0}' -f $BulletinID
            $Filters.Add($Additional_Filter)
        }
        if ($PSBoundParameters.ContainsKey('PatchStatus')) {
            $Additional_Filter = 'patchstatusfilter={0}' -f $Patch_Status_Mapping[$PatchStatus]
            $Filters.Add($Additional_Filter)
        }
        if ($PSBoundParameters.ContainsKey('ApprovalStatus')) {
            $Additional_Filter = 'approvalstatusfilter={0}' -f $Approval_Status_Mapping[$ApprovalStatus]
            $Filters.Add($Additional_Filter)
        }
        if ($PSBoundParameters.ContainsKey('Severity')) {
            $Additional_Filter = 'severityfilter={0}' -f $Severity_Mapping[$Severity]
            $Filters.Add($Additional_Filter)
        }

        if ($Filters.Count) {
            $API_Path += '?{0}' -f ($Filters -join '&')
        }

        $Query_Parameters = @{
            'AuthToken' = $AuthToken
            'HostName'  = $HostName
            'Port'      = $Port
            'APIPath'   = $API_Path
            'Method'    = 'GET'
        }
        Write-Verbose ('{0}|Calling Invoke-DCQuery' -f $Function_Name)
        $Query_Return = Invoke-DCQuery @Query_Parameters
        $Query_Return

    } catch {
        if ($_.FullyQualifiedErrorId -match '^DC-') {
            $Terminating_ErrorRecord = New-DefaultErrorRecord -InputObject $_
            $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
        } else {
            throw
        }
    }
}
