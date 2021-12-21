function Get-DCAPIComputer {
    <#
    .SYNOPSIS
        Gets the name, ID and domain for all computers, or some additional information if a resource ID is specified.
    .DESCRIPTION
        If no resource ID is given, this returns a list of all computers with only 3 properties: name, ID and domain.
        If a resource ID is supplied, then the same information plus OS flavour, OS ID and live status.
    .EXAMPLE
        Get-DCAPIComputer -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C'

        Gets a list of all registered computers.
    .EXAMPLE
        Get-DCAPIComputer -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 1000

        Gets the details of the computer with resource ID 1000.
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

        # The Resource ID to return.
        [Parameter(Mandatory = $false)]
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
        if ($PSBoundParameters.ContainsKey('ResourceID')) {
            $API_Path = 'dcapi/som/computers/{0}' -f $ResourceID
        } else {
            $API_Path = 'dcapi/inventory/computers'
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
