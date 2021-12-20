function Get-DCComputerInventorySummary {
    <#
    .SYNOPSIS
        Provides computer inventory summary information for a specific resource ID.
    .DESCRIPTION
        Returns summary inventory information for the specified resource ID.
        Although this is called "summary" information, it often returns more detailed information than other API endpoints.

        Details output include:
        - Asset summary - counts of installed software and hardware.
        - Disk summary - disk space configured, disk space used/free.
        - Hardware summary - memory, CPU, serial number.
        - Network adapter summary - IP address, gateway, MAC address, adapter name.
        - OS summary - OS name, version, product key.
        - Computer summary - hostname, domain and owner.
    .EXAMPLE
        Get-DCComputerInventorySummary -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101

        Returns summary inventory information for the resource with ID 101.
    .NOTES
        https://www.manageengine.com/products/desktop-central/api/api-inventory-computersdetailsummary.html
    #>

    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

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
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'inventory/compdetailssummary'
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
