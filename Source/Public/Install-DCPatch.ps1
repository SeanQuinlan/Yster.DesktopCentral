function Install-DCPatch {
    <#
    .SYNOPSIS
        Installs patches onto some or all resources.
    .DESCRIPTION
        Installs specified patches or all missing patches onto the supplied resources. Or installs the specified patches onto all resources or the supplied resources.

        If you include one or more PatchIDs, then those specified PatchIDs will be installed. If you supply one or more ResourceIDs, then the patches will only be installed on those.

        If you do not supply PatchID, then all missing PatchIDs will be installed. If you do not supply a ResourceID, then the patches will be installed onto all ResourceIDs where they are missing.

        You are required to supply either a PatchID or ResourceID, or both.

        Installation is done via a Configuration, and therefore the Configuration name and description are required, along with a Deployment Policy Template ID to use.
    .EXAMPLE
        Install-DCPatch -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101 -PatchID 300001 -ConfigurationName "DeploySpecificToHost" -ConfigurationDescription "Deploy specific patch to host" -DeploymentPolicyTemplateID 1

        Will create a Configuration to deploy the patch 300001 onto the resource with ID 101.
    .EXAMPLE
        Install-DCPatch -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -ResourceID 101 -ConfigurationName "DeployAllToHost" -ConfigurationDescription "Deploy all missing patches to host" -DeploymentPolicyTemplateID 1

        Will create a Configuration to deploy any missing patches onto the resource with ID 101.
    .EXAMPLE
        Install-DCPatch -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -PatchID 300001,300002 -ConfigurationName "DeploySpecificPatchesToAllHosts" -ConfigurationDescription "Deploy specific patches to all hosts that are missing" -DeploymentPolicyTemplateID 1

        Will create a Configuration to deploy patches with IDs 300001 and 300002 to all hosts that are missing that patch.
    .NOTES
        https://www.manageengine.com/patch-management/api/install-specific-patches-in-all-systems.html
        https://www.manageengine.com/patch-management/api/install-all-missing-patches-for-specific-systems.html
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

        # The PatchID or IDs to install.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int[]]
        $PatchID,

        # The Resource ID or IDs of the computers to install the patches on.
        [Parameter(Mandatory = $false)]
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

    if (-not ($PatchID -or $ResourceID)) {
        $Terminating_ErrorRecord_Parameters = @{
            'Exception'    = 'System.ArgumentException'
            'ID'           = 'DC-ParameterValidationError'
            'Category'     = 'InvalidArgument'
            'TargetObject' = $null
            'Message'      = 'Either PatchID or ResourceID has to be supplied.'
        }
        $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
        $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
    }

    try {
        $API_Path = 'patch/installpatch'
        $Body = @{
            'ConfigName'                 = $ConfigurationName
            'ConfigDescription'          = $ConfigurationDescription
            'actionToPerform'            = 'Deploy'
            'DeploymentPolicyTemplateID' = $DeploymentPolicyTemplateID
        }
        if ($PatchID) {
            $Body['PatchIDs'] = $PatchID
            if ($PatchID.Count -gt 1) {
                $PatchID_String = 'PatchIDs "{0}"' -f ($PatchID -join ',')
            } else {
                $PatchID_String = 'PatchID "{0}"' -f $($PatchID)
            }
        } else {
            $PatchID_String = 'all missing PatchIDs'
        }
        if ($ResourceID) {
            $Body['ResourceIDs'] = $ResourceID
            if ($ResourceID.Count -gt 1) {
                $ResourceID_String = 'ResourceIDs: {0}' -f ($ResourceID -join ',')
            } else {
                $ResourceID_String = 'ResourceID: {0}' -f $($ResourceID)
            }
        } else {
            $ResourceID_String = 'ResourceIDs: all'
        }
        $Query_Parameters = @{
            'AuthToken'            = $AuthToken
            'HostName'             = $HostName
            'APIPath'              = $API_Path
            'Method'               = 'POST'
            'SkipCertificateCheck' = $SkipCertificateCheck
            'Body'                 = $Body
        }

        $Confirm_Header = New-Object -TypeName 'System.Text.StringBuilder'
        [void]$Confirm_Header.AppendLine('Confirm')
        [void]$Confirm_Header.AppendLine('Are you sure you want to perform this action?')

        $Remove_ShouldProcess = New-Object -TypeName 'System.Text.StringBuilder'
        [void]$Remove_ShouldProcess.AppendLine(('Install {0} on {1}' -f $PatchID_String, $ResourceID_String))

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
