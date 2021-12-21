function Get-DCAPIRemoteOffice {
    <#
    .SYNOPSIS
        Gets details of all the remote offices configured, or just the specified remote office ID.
    .DESCRIPTION
        If no remote office ID is specified, return all the remote office details. Otherwise just return the details for the supplied ID.
    .EXAMPLE
        Get-DCAPIRemoteOffice -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C'

        Displays details for all the remote offices.
    .EXAMPLE
        Get-DCAPIRemoteOffice -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -RemoteOfficeID 1

        Returns the details for the remote office with ID 1.
    .NOTES
    #>

    [CmdletBinding()]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The Remote Office ID to return.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [Int]
        $RemoteOfficeID,

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
        if ($PSBoundParameters.ContainsKey('RemoteOfficeID')) {
            $API_Path = 'dcapi/som/remote-offices/{0}' -f $RemoteOfficeID
        } else {
            $API_Path = 'dcapi/som/remote-offices'
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
