function Invoke-DCInventoryScan {
    <#
    .SYNOPSIS
        Start the inventory (agent) scan process on the supplied resource ID or IDs.
    .DESCRIPTION
        Invokes the process to scan a device for it's inventory. Requires at least one resource ID to be supplied.
    .EXAMPLE
        Invoke-DCInventoryScan -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101,102,103

        Starts the inventory scan process on the specified resource IDs.
    .NOTES
        https://www.manageengine.com/products/desktop-central/api/api-inventory-computers-scan.html
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
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

        # The Resource ID or IDs to scan.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [Int[]]
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
        $API_Path = 'inventory/computers/scan'
        $Body = @{
            'resourceids' = $ResourceID
        }
        $Query_Parameters = @{
            'AuthToken'            = $AuthToken
            'HostName'             = $HostName
            'APIPath'              = $API_Path
            'Method'               = 'POST'
            'SkipCertificateCheck' = $SkipCertificateCheck
            'Body'                 = $Body
        }

        $ShouldProcess_Statement = New-Object -TypeName 'System.Text.StringBuilder'
        [void]$ShouldProcess_Statement.AppendLine(('Start an inventory scan on these computers: {0}' -f ($ResourceID -join ',')))

        $Whatif_Statement = $ShouldProcess_Statement.ToString().Trim()
        $Confirm_Statement = ('Are you sure you want to perform this action?', $Whatif_Statement) -join [Environment]::NewLine
        if ($PSCmdlet.ShouldProcess($Whatif_Statement, $Confirm_Statement, 'Confirm')) {
            Write-Verbose ('{0}|Calling Invoke-DCQuery' -f $Function_Name)
            $Query_Return = Invoke-DCQuery @Query_Parameters
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
