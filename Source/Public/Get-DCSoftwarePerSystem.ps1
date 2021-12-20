function Get-DCSoftwarePerSystem {
    <#
    .SYNOPSIS
        Returns a list of software installed on the provided resource ID.
    .DESCRIPTION
        Gets a list of software installed on the specified resource ID or IDs.

        This can further be filtered by access type, compliance status, license type and OS compatibility (32-bit or 64-bit).
    .EXAMPLE
        Get-DCSoftwarePerSystem -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101

        Returns all the software installed on resource 101.
    .NOTES
        https://www.manageengine.com/products/desktop-central/api/api-inventory-computerinstalledsoftware.html
    #>

    [CmdletBinding()]
    param(
        # The AccessType to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('NotAssigned', 'Allowed', 'Prohibited')]
        [String]
        $AccessType,

        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The ComplianceStatus to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('NotAvailable', 'UnderLicensed', 'OverLicensed', 'InCompliance', 'Expired')]
        [String]
        $ComplianceStatus,

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

        # The LicenseType to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Unidentified', 'Commercial', 'NonCommercial')]
        [String]
        $LicenseType,

        # The OS Compatibility to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('32-bit', '64-bit', 'Neutral')]
        [String]
        $OSCompatibility,

        # The Resource ID to return.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [Int]
        $ResourceID,

        # Whether to skip the SSL certificate check.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $SkipCertificateCheck
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'inventory/installedsoftware'
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
