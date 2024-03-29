function Get-DCAPIComputerGroups {
    <#
    .SYNOPSIS
        Gets a list of local groups for the supplied computer resource.
    .DESCRIPTION
        Returns a list of all local groups configured on the specified resource ID or name.
        If querying a domain controller, all domain groups will be returned.
    .EXAMPLE
        Get-DCAPIComputerGroups -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101

        Returns the list of local groups on resource ID 101.
    .EXAMPLE
        Get-DCAPIComputerGroups -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceName SRV1

        Gets all local groups on resource named "SRV1".
    .NOTES
    #>

    [CmdletBinding(DefaultParameterSetName = 'ResourceID')]
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
        [Parameter(Mandatory = $true, ParameterSetName = 'ResourceID')]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [Int]
        $ResourceID,

        # The Resource Name to return.
        [Parameter(Mandatory = $true, ParameterSetName = 'ResourceName')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ResourceName,

        # Whether to skip the SSL certificate check.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $SkipCertificateCheck
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $Common_Parameters = @{
            'AuthToken'            = $AuthToken
            'HostName'             = $HostName
            'SkipCertificateCheck' = $SkipCertificateCheck
        }

        if ($PSBoundParameters.ContainsKey('ResourceName')) {
            Write-Verbose ('{0}|Calling Get-DCAPIComputer' -f $Function_Name)
            $Computer_Lookup = Get-DCAPIComputer @Common_Parameters | Group-Object -Property 'computerName' -AsHashTable

            if (-not $Computer_Lookup[$ResourceName]) {
                $Terminating_ErrorRecord_Parameters = @{
                    'Exception'    = 'System.Exception'
                    'ID'           = 'DC-ResourceNameNotFound'
                    'Category'     = 'ObjectNotFound'
                    'TargetObject' = $ResourceName
                    'Message'      = 'Unable to find ID for resource: {0}' -f $ResourceName
                }
                $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
            }
            $ResourceID = $Computer_Lookup[$ResourceName].computerID
        }

        $API_Path = 'dcapi/inventory/computers/{0}/groups' -f $ResourceID
        $Query_Parameters = @{
            'APIPath' = $API_Path
            'Method'  = 'GET'
        }
        Write-Verbose ('{0}|Calling Invoke-DCQuery' -f $Function_Name)
        $Query_Return = Invoke-DCQuery @Common_Parameters @Query_Parameters
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
