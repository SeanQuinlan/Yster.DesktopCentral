function Get-DCAPIResource {
    <#
    .SYNOPSIS
        Returns a list of resources (users or computers), filtered by certain parameters.
    .DESCRIPTION
        Returns a list of user or computer resources based on the filters or search criteria provided.

        For users, only name, domain and resource ID are returned.
        For computers, name, domain, resource ID and OS platform are returned.
    .EXAMPLE
        Get-DCAPIResource -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceType computer

        Returns a list of all computer resources on the server.
    .EXAMPLE
        Get-DCAPIResource -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceType computer -Domain 'CONTOSO' -Search 'SRV'

        Returns a list of all computer resources in the CONTOSO domain with the characters "SRV" somewhere in the name.
    .EXAMPLE
        Get-DCAPIResource -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceType user -Search 'admin'

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

        # The hostname/FQDN/IP address of the Desktop Central server.
        # By default, HTTPS will be used for connection.
        # If you want to connect via HTTP, then prefix the hostname with "http://"
        #
        # Examples of use:
        # -HostName deskcent01
        # -HostName http://deskcent01
        # -HostName deskcent01.contoso.com
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $HostName,

        # Limit the number of results that are returned.
        # The default is to return all results.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('Limit', 'PageLimit')]
        [Int]
        $ResultSize = 0,

        # The range index to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $RangeIndex = 0,

        # The type of resource to return - user or computer.
        [Parameter(Mandatory = $true)]
        [ValidateSet('Computer', 'User')]
        [Alias('GroupType')]
        [String]
        $ResourceType,

        # The string to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('CharFilter')]
        [String]
        $Search = '',

        # Whether to skip the SSL certificate check.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $SkipCertificateCheck,

        # The sort order of the results.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Ascending', 'Descending')]
        [String]
        $SortOrder
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $API_Path = 'dcapi/customGroups/availableResources'
        $API_Body = @{
            'charFilter'    = $Search
            'groupCategory' = $GroupCategoryName_Mapping[$GroupCategory]
            'groupType'     = $GroupTypeName_Mapping[$ResourceType]
            'limit'         = $ResultSize
            # This can be used to get another "page" of results by setting the index to limit+1
            'rangeIndex'    = $RangeIndex
        }
        if ($PSBoundParameters.ContainsKey('Domain')) {
            $API_Body['domainFilter'] = $Domain
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
            'AuthToken'            = $AuthToken
            'HostName'             = $HostName
            'APIPath'              = $API_Path
            'Method'               = 'POST'
            'SkipCertificateCheck' = $SkipCertificateCheck
            'Body'                 = $API_Body
            'Header'               = $API_Header
            'ContentType'          = 'application/availableResourcesDetail.v1+json'
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
