function Get-DCPatchDetail {
    <#
    .SYNOPSIS
        Gets the details of every patch within the environment.
    .DESCRIPTION
        Provides a more detailed view of every patch, with a separate entry for each patch on each computer.

        Can be filtered down to a specific domain, patch ID, bulletin ID, severity or install status.
    .EXAMPLE
        Get-DCPatchDetail -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -PatchID 500107

        Gets the status of the patch with the ID 500107, with a separate entry for every computer it applies to.
    .EXAMPLE
        Get-DCPatchDetail -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -PatchID 31923 -PatchStatus Missing | Select-Object resource_name

        Return the names of all computers that are missing the patch with ID 31923.
    .NOTES
        https://www.manageengine.com/patch-management/api/all-patch-details-patch-management.html
    #>

    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The Branch Office to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $BranchOffice,

        # The BulletinID to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $BulletinID,

        # The Custom Group name to filter on.
        # NOTE: This field is case-sensitive.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $CustomGroup,

        # The NETBIOS name of the Domain to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,

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

        # The PatchID to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $PatchID,

        # The Patch Status to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Installed', 'Missing', 'Failed')]
        [String]
        $PatchStatus,

        # The Platform to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Mac', 'Windows', 'Linux')]
        [String]
        $Platform,

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

        # The Severity to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Unrated', 'Low', 'Moderate', 'Important', 'Critical')]
        [String]
        $Severity,

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
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'patch/allpatchdetails'
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
