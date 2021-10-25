function Get-DCDownloadedPatches {
    <#
    .SYNOPSIS
        Gets a list of all downloaded patches.
    .DESCRIPTION
        Outputs a list of all patches that have been downloaded.
    .EXAMPLE
        Get-DCDownloadedPatches -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C'

        Returns properties for all downloaded patches.
    .NOTES
        https://www.manageengine.com/patch-management/api/get-downloaded-patch.html
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

        # The page of results to return.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Page,

        # Limit the number of results that are returned.
        # The default is to return all results.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('Limit', 'PageLimit')]
        [Int]
        $ResultSize = 0,

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
        $PSBoundParameters['ResultSize'] = $ResultSize
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'patch/downloadedpatches'
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
