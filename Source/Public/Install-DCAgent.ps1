function Install-DCAgent {
    <#
    .SYNOPSIS
        Installs the agent on the supplied resource ID or IDs.
    .DESCRIPTION
        Installs the Desktop Central agent on the resource with the given ID or IDs.
    .EXAMPLE
        Install-DCAgent -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101

        Attempts to install the Desktop Central agent on the resource with ID 101.
    .NOTES
        https://www.manageengine.com/patch-management/api/api-som-computer-actions.html
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

        # The Resource ID or IDs of the computers to install the agent on.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
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
        $API_Path = 'som/computers/installagent'
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
        [void]$ShouldProcess_Statement.AppendLine(('Install agent on ResourceIDs: {0}' -f ($ResourceID -join ',')))

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
