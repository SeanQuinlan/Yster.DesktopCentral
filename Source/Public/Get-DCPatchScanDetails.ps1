function Get-DCPatchScanDetails {
    <#
    .SYNOPSIS
        Gets the patch scan details of one or all devices.
    .DESCRIPTION
        Outputs the patch scan details of all devices, or filtered by Resource ID, Custom Group, branch office, domain or other filters.
    .EXAMPLE
        Get-DCPatchScanDetails -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C'

        Returns the patch scan status of every device.
    .EXAMPLE
        Get-DCPatchScanDetails -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101

        Returns just the patch scan status of the device with ID 101.
    .NOTES
        https://www.manageengine.com/patch-management/api/patch-scan-details-patch-management.html
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

        # The NETBIOS name of The NETBIOS name of the Domain to filter on.
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
        [ValidateSet('Mac', 'Windows', 'Linux')]
        [String]
        $Platform,

        # The Resource ID to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [Int]
        $ResourceID,

        # The Health to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Unknown', 'Healthy', 'Vulnerable', 'HighlyVulnerable')]
        [String]
        $Health,

        # The LiveStatus to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Live', 'Down', 'Unknown')]
        [String]
        $LiveStatus,

        # The Agent Installation Status to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Installed', 'NotInstalled')]
        [String]
        $AgentInstallationStatus
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    # testing
    # -------
    # [x] domain
    # [ ] branch office
    # [ ] custom group
    # [x] platform
    # [x] resourceid
    # [x] health
    # [x] livestatus
    # [x] agent installation

    try {
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'patch/scandetails'
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
