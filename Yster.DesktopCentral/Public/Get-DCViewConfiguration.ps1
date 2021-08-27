function Get-DCViewConfiguration {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .EXAMPLE

    .NOTES
        https://www.manageengine.com/patch-management/api/view-configuration-patch-management.html
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

        # The Config Status to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('InProgress', 'Draft', 'Executed', 'Suspended', 'Deployed', 'RetryInProgress', 'Expired')]
        [String]
        $ConfigStatus
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    # branch office filters with spaces?

    # testing
    # -------
    # [ ] domain
    # [ ] branch office
    # [ ] config status

    try {
        $API_Path = 'patch/viewconfig'
        $Filters = New-Object -TypeName 'System.Collections.Generic.List[String]'
        if ($PSBoundParameters.ContainsKey('Domain')) {
            $Additional_Filter = 'domainfilter={0}' -f $Domain
            $Filters.Add($Additional_Filter)
        }
        if ($PSBoundParameters.ContainsKey('BranchOffice')) {
            $Additional_Filter = 'branchofficefilter={0}' -f $BranchOffice
            $Filters.Add($Additional_Filter)
        }
        if ($PSBoundParameters.ContainsKey('ConfigStatus')) {
            $Additional_Filter = 'configstatusfilter={0}' -f $ConfigStatus
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
