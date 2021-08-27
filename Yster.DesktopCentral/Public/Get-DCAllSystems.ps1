function Get-DCAllSystems {
    <#
    .SYNOPSIS
        Gets the list of computers and their patch status.
    .DESCRIPTION
        Provides a more detailed view of every computer's patch status.
    .EXAMPLE
        Get-DCAllSystems -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C'

        Gets the patch status of all computers.
    .EXAMPLE
        Get-DCAllSystems -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 308

        Return the patch status of the computer with ID 308.
    .NOTES
        https://www.manageengine.com/patch-management/api/all-systems-patch-management.html
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
        $Health
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    # branch office filters with spaces?

    # testing
    # -------
    # [x] domain
    # [ ] branch office
    # [ ] custom group
    # [x] platform
    # [x] resourceid
    # [x] health

    try {
        $API_Path = 'patch/allsystems'
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
        if ($PSBoundParameters.ContainsKey('ResourceID')) {
            $Additional_Filter = 'resid={0}' -f $ResourceID
            $Filters.Add($Additional_Filter)
        }
        if ($PSBoundParameters.ContainsKey('Health')) {
            $Additional_Filter = 'healthfilter={0}' -f $Health_Mapping[$Health]
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
