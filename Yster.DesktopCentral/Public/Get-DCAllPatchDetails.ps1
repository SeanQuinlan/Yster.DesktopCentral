function Get-DCAllPatchDetails {
    <#
    .SYNOPSIS
        Gets the details of every patch within the environment.
    .DESCRIPTION
        Provides a more detailed view of every patch, with a separate entry for each patch on each computer.
        Can be filtered down to a specific domain, patch ID, bulletin ID, severity or install status.
    .EXAMPLE
        Get-DCAllPatchDetails -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -PatchID 500107

        Gets the status of the patch with the ID 500107, with a separate entry for every computer it applies to.
    .EXAMPLE
        Get-DCAllPatchDetails -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -PatchID 31923 -PatchStatus Missing | Select-Object resource_name

        Return the names of all computers that are missing the patch with ID 31923.
    .NOTES
        https://www.manageengine.com/patch-management/api/all-patch-details-patch-management.html
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
        [ValidateSet('Installed', 'Missing', 'Failed')]
        [String]
        $PatchStatus,

        # The Severity to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Unrated', 'Low', 'Moderate', 'Important', 'Critical')]
        [String]
        $Severity
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    # testing
    # -------
    # [x] domain
    # [ ] branch office
    # [ ] custom group
    # [o] platform - no difference if I use "mac", still same results as "windows" or nothing. Doesn't matter what I put into platformfilter
    # [x] patchid
    # [x] bulletinid
    # [x] patchstatus - works fine for this function
    # [x] severity

    try {
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'patch/allpatchdetails'
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
