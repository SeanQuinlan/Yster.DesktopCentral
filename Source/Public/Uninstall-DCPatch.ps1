function Uninstall-DCPatch {
    <#
    .SYNOPSIS
        Uninstalls a patch or patches from supplied resources.
    .DESCRIPTION
        Uninstalls the specified patch or patches from the supplied resources.

        Both PatchID and ResourceID are required.

        Uninstallation is done via a Configuration, and therefore the Configuration name and description are required, along with a Deployment Policy Template ID to use.
    .EXAMPLE
        Uninstall-DCPatch -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101 -PatchID 300001 -ConfigurationName "UninstallPatch" -ConfigurationDescription "Uninstall patch from specific system" -DeploymentPolicyTemplateID 1

        Will create a Configuration to uninstall the patch 300001 from the resource with ID 101.
    .NOTES
        https://www.manageengine.com/patch-management/api/uninstall-specific-patches-in-all-systems.html
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The name of the Configuration to create.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ConfigName')]
        [String]
        $ConfigurationName,

        # The description of the Configuration.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ConfigDescription')]
        [String]
        $ConfigurationDescription,

        # The Deployment Policy TemplateID to use for the Configuration.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('DeploymentID')]
        [Int]
        $DeploymentPolicyTemplateID,

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

        # The PatchID or IDs to uninstall.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Int[]]
        $PatchID,

        # The port of the Desktop Central server.
        # Only set this if the server is running on a different port to the default.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Port = 8020,

        # The Resource ID or IDs of the computers to uninstall the patches from.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Int[]]
        $ResourceID
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $API_Path = 'patch/uninstallpatch'
        $Body = @{
            'ConfigName'                 = $ConfigurationName
            'ConfigDescription'          = $ConfigurationDescription
            'actionToPerform'            = 'Deploy'
            'DeploymentPolicyTemplateID' = $DeploymentPolicyTemplateID
            'PatchIDs'                   = $PatchID
            'ResourceIDs'                = $ResourceID
        }
        if ($PatchID.Count -gt 1) {
            $PatchID_String = 'PatchIDs "{0}"' -f ($PatchID -join ',')
        } else {
            $PatchID_String = 'PatchID "{0}"' -f $($PatchID)
        }
        if ($ResourceID.Count -gt 1) {
            $ResourceID_String = 'ResourceIDs: {0}' -f ($ResourceID -join ',')
        } else {
            $ResourceID_String = 'ResourceID: {0}' -f $($ResourceID)
        }
        $Query_Parameters = @{
            'AuthToken' = $AuthToken
            'HostName'  = $HostName
            'Port'      = $Port
            'APIPath'   = $API_Path
            'Method'    = 'POST'
            'Body'      = $Body
        }

        $Confirm_Header = New-Object -TypeName 'System.Text.StringBuilder'
        [void]$Confirm_Header.AppendLine('Confirm')
        [void]$Confirm_Header.AppendLine('Are you sure you want to perform this action?')

        $Remove_ShouldProcess = New-Object -TypeName 'System.Text.StringBuilder'
        [void]$Remove_ShouldProcess.AppendLine(('Uninstall {0} on {1}' -f $PatchID_String, $ResourceID_String))

        $Whatif_Statement = $Remove_ShouldProcess.ToString().Trim()
        $Confirm_Statement = $Whatif_Statement
        if ($PSCmdlet.ShouldProcess($Whatif_Statement, $Confirm_Statement, $Confirm_Header.ToString())) {
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
