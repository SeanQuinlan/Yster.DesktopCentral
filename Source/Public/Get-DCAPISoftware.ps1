function Get-DCAPISoftware {
    <#
    .SYNOPSIS
        Gets the list of software configured on the Desktop Central server, or a more detailed result from a specified software ID.
    .DESCRIPTION
        If no ID is supplied, this returns a list of all software available on the server, along with some basic information (Name, Manufacturer, Version, etc)
        Specifying a software ID will return more detail on that software configuration.
    .EXAMPLE
        Get-DCAPISoftware -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C'

        Gets a list of all configured software from the server.
    .EXAMPLE
        Get-DCAPISoftware -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -SoftwareID 100

        Returns the details of the software with ID 100.
    .NOTES
    #>

    [CmdletBinding()]
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

        # Whether to skip the SSL certificate check.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $SkipCertificateCheck,

        # The Software ID to return.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [Int]
        $SoftwareID
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        if ($PSBoundParameters.ContainsKey('SoftwareID')) {
            $API_Path = 'dcapi/inventory/software/{0}' -f $SoftwareID
        } else {
            $API_Path = 'dcapi/inventory/software'
        }
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
