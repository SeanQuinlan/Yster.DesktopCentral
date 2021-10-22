function Get-DCCustomGroup {
    <#
    .SYNOPSIS
        Gets details of all custom groups or a filtered list of custom groups.
    .DESCRIPTION
        Returns a list of custom groups and details for each of those groups.

        With no filters it will return all groups on the server, or can be filtered by group ID (single or array of IDs), group category (Static, StaticUnique or Dynamic) or by group type (user or computer).
    .EXAMPLE
        Get-DCCustomGroup -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C'

        Returns all custom groups on the server.
    .EXAMPLE
        Get-DCCustomGroup -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -GroupID 601,301,304

        Returns the custom groups with the IDs 601, 301 and 304.
    .EXAMPLE
        Get-DCCustomGroup -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -GroupType 'Computer' -GroupCategory 'Static'

        Returns all the static computer custom groups.
    .NOTES

    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The category of custom group to filter on - Static, StaticUnique or Dynamic.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Static', 'StaticUnique', 'Dynamic')]
        [String]
        $GroupCategory,

        # The Group ID or IDs to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('ID', 'ResourceID')]
        [Int[]]
        $GroupID,

        # The type of custom group to filter on - user or computer.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Computer', 'User')]
        [String]
        $GroupType,

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

        # The port of the Desktop Central server.
        # Only set this if the server is running on a different port to the default.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Port = 8020
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'dcapi/customGroups'
        if (-not $GroupCategory -and -not $GroupType -and -not $GroupID) {
            # The header must be changed if no filters are applied
            $API_Header = @{
                'Accept' = 'application/allCustomGroupDetails.v1+json'
            }
        } else {
            $API_Header = @{
                'Accept' = 'application/customGroupDetails.v1+json'
            }
        }
        $Query_Parameters = @{
            'AuthToken' = $AuthToken
            'HostName'  = $HostName
            'Port'      = $Port
            'APIPath'   = $API_Path
            'Method'    = 'GET'
            'Header'    = $API_Header
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
