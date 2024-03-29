function Get-DCServerOptions {
    <#
    .SYNOPSIS
        Gets some basic information about the Desktop Central Server.
    .DESCRIPTION
        Gets a basic set of options for the Desktop Central server, such as what type of authentication is supported.

        This information does not require authentication first, so can be used to determine how to connect to a server.
    .EXAMPLE
        Get-DCServerOptions -HostName DCSERVER

        Returns basic options for the server.
    .NOTES
        https://www.manageengine.com/patch-management/api/api-common-discover.html
    #>

    [CmdletBinding()]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $false)]
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
        $SkipCertificateCheck
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $API_Path = 'desktop/discover'
        $Query_Parameters = @{
            'HostName'             = $HostName
            'APIPath'              = $API_Path
            'Method'               = 'GET'
            'SkipCertificateCheck' = $SkipCertificateCheck
        }
        if ($PSBoundParameters.ContainsKey('AuthToken')) {
            $Query_Parameters['AuthToken'] = $AuthToken
        }
        Write-Verbose ('{0}|Calling Invoke-DCQuery' -f $Function_Name)
        $Query_Return = Invoke-DCQuery @Query_Parameters
        $Query_Return.login_data

    } catch {
        if ($_.FullyQualifiedErrorId -match '^DC-') {
            $Terminating_ErrorRecord = New-DefaultErrorRecord -InputObject $_
            $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
        } else {
            throw
        }
    }
}
