function Get-DCSoftwareComputers {
    <#
    .SYNOPSIS
        Returns a list of software configured on the Desktop Central server.
    .DESCRIPTION
        Gets a list of all software, or filtered by domain, access type, license type or compliance status.
    .EXAMPLE
        Get-DCSoftware -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C'

        Returns all configured software on the server.
    .NOTES
        https://www.manageengine.com/products/desktop-central/api/api-inventory-softwarecomputers.html
    #>

    [CmdletBinding()]
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

        # The Custom Group name to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $CustomGroup,

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

        # The LiveStatus to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Live', 'Down', 'Unknown')]
        [String]
        $LiveStatus,

        # The OS Compatibility to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('32-bit', '64-bit', 'Neutral')]
        [String]
        $OSCompatibility,

        # The ID of the software to return.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('SWID')]
        [Int]
        $SoftwareID,

        # Whether to skip the SSL certificate check.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $SkipCertificateCheck
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'inventory/computers'   #########
        $Query_Parameters = @{
            'AuthToken'            = $AuthToken
            'HostName'             = $HostName
            'APIPath'              = $API_Path
            'Method'               = 'GET'
            'SkipCertificateCheck' = $SkipCertificateCheck
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
