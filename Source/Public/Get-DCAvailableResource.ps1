function Get-DCAvailableResource {
    <#
    .SYNOPSIS
        Returns a list of resources (users or computers), filtered by certain parameters.
    .DESCRIPTION
        Returns a list of user or computer resources based on the filters or search criteria provided.

        For users, only name, domain and resource ID are returned.
        For computers, name, domain, resource ID and OS platform are returned.
    .EXAMPLE
        Get-DCAvailableResource -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -GroupType computer

        Returns a list of all computer resources on the server.
    .EXAMPLE
        Get-DCAvailableResource -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -GroupType computer -Domain 'CONTOSO' -Search 'SRV'

        Returns a list of all computer resources in the CONTOSO domain with the characters "SRV" somewhere in the name.
    .EXAMPLE
        Get-DCAvailableResource -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -GroupType user -Search 'admin'

        Returns a list of all user resources with the characters "admin" somewhere in the name.
    .NOTES

    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The NETBIOS name of the Domain or Domains to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Domain,

        # The category of custom group to filter on - Static or StaticUnique.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Static', 'StaticUnique')]
        [String]
        $GroupCategory = 'Static',

        # The type of custom group to filter on - user or computer.
        [Parameter(Mandatory = $true)]
        [ValidateSet('Computer', 'User')]
        [String]
        $GroupType,

        # The hostname of the Desktop Central server.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $HostName,

        # Limit the number of results that are returned.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Limit,

        # The port of the Desktop Central server.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Port = 8020,

        # The range index to filter on.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $RangeIndex,

        # The string to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('CharFilter')]
        [String]
        $Search = '',

        # The sort order of the results.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Ascending', 'Descending')]
        [String]
        $SortOrder
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    # Tests:
    # -------
    # [x] domain
    # [x] limit
    # [o] rangeindex - doesn't seem to do anything if set to 0 or 1 (only 2 assets though). 2 returns just the 2nd one, 3+ returns nothing
    # [o] sort order - doesn't seem to do anything

    try {
        $API_Path = 'dcapi/customGroups/availableResources'
        $API_Body = @{
            'charFilter'    = $Search
            'groupCategory' = $Group_Categories_Mapping[$GroupCategory]
            'groupType'     = $Group_Types_Mapping[$GroupType]
        }
        if ($PSBoundParameters.ContainsKey('Domain')) {
            $API_Body['domainFilter'] = $Domain
        }
        if ($PSBoundParameters.ContainsKey('Limit')) {
            $API_Body['limit'] = $Limit
        }
        if ($PSBoundParameters.ContainsKey('RangeIndex')) {
            $API_Body['rangeIndex'] = $RangeIndex
        }
        if ($PSBoundParameters.ContainsKey('SortOrder')) {
            if ($SortOrder -eq 'Ascdending') {
                $SortOrderType = 'asc'
            } else {
                $SortOrderType = 'desc'
            }
            $API_Body['sortOrder'] = $SortOrderType
        }
        $API_Header = @{
            'Accept' = 'application/availableResources.v1+json'
        }
        $Query_Parameters = @{
            'AuthToken'   = $AuthToken
            'HostName'    = $HostName
            'Port'        = $Port
            'APIPath'     = $API_Path
            'Method'      = 'POST'
            'Body'        = $API_Body
            'Header'      = $API_Header
            'ContentType' = 'application/availableResourcesDetail.v1+json'
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
