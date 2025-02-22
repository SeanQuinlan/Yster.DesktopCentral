function Get-DCComputerInventory {
    <#
    .SYNOPSIS
        Gets inventory details of one or more computers.
    .DESCRIPTION
        Returns a list of computer objects with details around inventory, such as the status of the agent.
        These results can be filtered by Resource ID, office, domain, live status, installation status or scan status.
    .EXAMPLE
        Get-DCComputerInventory -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C'

        Gets a list of all registered computers along with their inventory status.
    .EXAMPLE
        Get-DCComputerInventory -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceId 101

        Returns just the inventory properties of the computer with ID 101.
    .NOTES
        https://www.manageengine.com/products/desktop-central/api/api-inventory-scancomputers.html
    #>

    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The Branch Office to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $BranchOffice,

        # The NETBIOS name of the Domain to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,

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

        # The Install Status to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('YetToInstall', 'Installed', 'Uninistalled', 'YetToUninstall', 'InstallationFailure')]
        [String]
        $InstallStatus,

        # The LiveStatus to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Live', 'Down', 'Unknown')]
        [String]
        $LiveStatus,

        # The Resource ID to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [Int]
        $ResourceID,

        # Limit the number of results that are returned.
        # The default is to return all results.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('Limit', 'PageLimit')]
        [Int]
        $ResultSize = 0,

        # The Scan Status to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('NotDone', 'Failed', 'InProgress', 'Success')]
        [String]
        $ScanStatus,

        # The name of the field to search on.
        [Parameter(Mandatory = $false)]
        [Parameter(Mandatory = $true, ParameterSetName = 'Search')]
        [ValidateNotNullOrEmpty()]
        [String]
        $SearchField,

        # The value to search on, in the specified field.
        [Parameter(Mandatory = $false)]
        [Parameter(Mandatory = $true, ParameterSetName = 'Search')]
        [ValidateNotNullOrEmpty()]
        [String]
        $SearchValue,

        # Whether to skip the SSL certificate check.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $SkipCertificateCheck
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        if ($PSBoundParameters.ContainsKey('ResourceID')) {
            [void]$PSBoundParameters.Remove('ResourceID')
            [void]$PSBoundParameters.Add('ResourceIDFilter', $ResourceID)
        }
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'inventory/scancomputers'
        $Query_Parameters = @{
            'AuthToken'            = $AuthToken
            'HostName'             = $HostName
            'APIPath'              = $API_Path
            'Method'               = 'GET'
            'SkipCertificateCheck' = $SkipCertificateCheck
            'ResultSize'           = $ResultSize
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
