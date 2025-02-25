function Get-DCPatchPerSystem {
    <#
    .SYNOPSIS
        Gets a list of all patches associated with a specific Resource ID.
    .DESCRIPTION
        Returns a list of all patches related to the supplied Resource ID. The patches can be further filtered by platform, severity, status, etc.
    .EXAMPLE
        Get-DCPatchPerSystem -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101

        Returns details of all patches related to resource 101.
    .EXAMPLE
        Get-DCPatchPerSystem -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101 -Severity Critical

        Returns details of only critical patches related to resource 101.
    .NOTES
        https://www.manageengine.com/patch-management/api/system-report-patch-management.html
    #>

    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        # The Approval Status to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Approved', 'NotApproved', 'Declined')]
        [String]
        $ApprovalStatus,

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

        # The Patch Status to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Installed', 'Missing')]
        [String]
        $PatchStatus,

        # The Platform to filter on.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Mac', 'Windows', 'Linux')]
        [String]
        $Platform,

        # The Resource ID to filter on.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [Int]
        $ResourceID,

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
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'patch/systemreport'
        $Query_Parameters = @{
            'AuthToken'            = $AuthToken
            'HostName'             = $HostName
            'APIPath'              = $API_Path
            'Method'               = 'GET'
            'SkipCertificateCheck' = $SkipCertificateCheck
            'ResultSize'           = $ResultSize
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
