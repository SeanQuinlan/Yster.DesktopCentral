function Get-DCAPISoftwareCategory {
    <#
    .SYNOPSIS
        Gets the list of software categories (name and category ID) configured on the Desktop Central server, or more detailed properties if a category ID is supplied.
    .DESCRIPTION
        If no ID is supplied, this returns a list of all software categories available on the server. This list consists of the category ID and the name of the category.
        Specifying a category ID will return more detail on that software category.
    .EXAMPLE
        Get-DCAPISoftwareCategory -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C'

        Gets a list of all software categories from the server.
    .EXAMPLE
        Get-DCAPISoftwareCategory -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -CategoryID 1

        Returns the details of the software category with ID 1.
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

        # The Category ID to return.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [Int]
        $CategoryID
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        if ($PSBoundParameters.ContainsKey('CategoryID')) {
            $API_Path = 'dcapi/inventory/software/category/{0}' -f $CategoryID
        } else {
            $API_Path = 'dcapi/inventory/software/softwareCategories'
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
