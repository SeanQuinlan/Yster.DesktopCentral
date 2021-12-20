function Get-DCAPIComputerSummary {
    <#
    .SYNOPSIS
        Gets all the summary information for the specified system, or only the specified type.
    .DESCRIPTION
        Returns all the different summary information objects for the specified resource ID.
        Alternatively, a more specific type can be provided: Asset, DiskUsage, General, Hardware or OS.
    .EXAMPLE
        Get-DCAPIComputerSummary -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101

        Returns an object containing all summary information for the resource ID 101.
    .EXAMPLE
        Get-DCAPIComputerSummary -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101 -Type OS

        Returns an object containing OS summary information for the resource ID 101.
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
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [Int]
        $ResourceID,

        # Whether to skip the SSL certificate check.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $SkipCertificateCheck,

        # The specific summary information to return.
        [Parameter(Mandatory = $false)]
        [ValidateSet(
            'Asset',
            'DiskUsage',
            'General',
            'Hardware',
            'OS'
        )]
        [String]
        $Type
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    $SummaryType_Mapping = @{
        'Asset'     = 'assetSummary'
        'DiskUsage' = 'diskUsageSummary'
        'General'   = 'generalSummary'
        'Hardware'  = 'hardwareSummary'
        'OS'        = 'osInformation'
    }

    try {
        if ($PSBoundParameters.ContainsKey('Type')) {
            $API_Path = 'dcapi/inventory/computers/{0}/{1}' -f $ResourceID, $SummaryType_Mapping[$Type]
        } else {
            $API_Path = 'dcapi/inventory/computers/{0}/summary' -f $ResourceID
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
