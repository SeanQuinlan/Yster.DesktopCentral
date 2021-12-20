function Get-DCAPIInventoryScanNextScheduledDate {
    <#
    .SYNOPSIS
        Gets the next scheduled date and time for the inventory scan, as well as whether the scan is enabled or not.
    .DESCRIPTION
        Returns an object with the next scheduled date for the inventory scan, along with a property indicating whether the scan is scheduled or not.
        If there is no schedule, then the isScheduled property will be "false" and the next scheduled time will be blank.
    .EXAMPLE
        Get-DCAPIInventoryScanNextScheduledDate -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C'

        Returns the date and time for the next scheduled inventory scan, as well as whether the scan is enabled or not.
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
        $SkipCertificateCheck
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $API_Path = 'dcapi/inventory/scheduleScan/nextExecutionTime'
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
