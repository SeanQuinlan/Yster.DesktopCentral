function Invoke-DCAPIWarrantyScan {
    <#
    .SYNOPSIS
        Start a warranty scan for the supplied resource.
    .DESCRIPTION
        Invokes the process to scan for a warranty for the supplied resource ID or name.
    .EXAMPLE
        Invoke-DCAPIWarrantyScan -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101

        Starts the warranty scan process for resource ID 101.
    .EXAMPLE
        Invoke-DCAPIWarrantyScan -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceName 'SRV1'

        Starts the warranty scan process for the computer with name "SRV1".
    .NOTES
    #>

    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ResourceID')]
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

        # The Resource ID to target.
        [Parameter(Mandatory = $true, ParameterSetName = 'ResourceID')]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [Int]
        $ResourceID,

        # The Resource Name to target.
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

        $API_Path = 'dcapi/inventory/computers/{0}/scanWarranty' -f $ResourceID
        $Query_Parameters = @{
            'APIPath' = $API_Path
            'Method'  = 'GET'
        }

        $ShouldProcess_Statement = New-Object -TypeName 'System.Text.StringBuilder'
        [void]$ShouldProcess_Statement.AppendLine(('Start a warranty scan on this computer: {0}' -f $ResourceID))

        $Whatif_Statement = $ShouldProcess_Statement.ToString().Trim()
        $Confirm_Statement = ('Are you sure you want to perform this action?', $Whatif_Statement) -join [Environment]::NewLine
        if ($PSCmdlet.ShouldProcess($Whatif_Statement, $Confirm_Statement, 'Confirm')) {
            Write-Verbose ('{0}|Calling Invoke-DCQuery' -f $Function_Name)
            $Query_Return = Invoke-DCQuery @Common_Parameters @Query_Parameters
            $Query_Return
        }

    } catch {
        if ($_.FullyQualifiedErrorId -match '^DC-') {
            $Terminating_ErrorRecord = New-DefaultErrorRecord -InputObject $_
            $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
        } else {
            throw
        }
    }
}
