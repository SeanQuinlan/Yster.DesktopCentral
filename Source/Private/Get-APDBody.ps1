function Get-APDBody {
    <#
    .SYNOPSIS
        Returns a Body hashtable to use in APD queries.
    .DESCRIPTION
        Looks through the BoundParameters hashtable and creates the appropriate Body hashtable for use in New-DCAPDTask and Set-DCAPDTask.
    .EXAMPLE
        $Body = Get-APDBody -Type 'New' -BoundParameters $PSBoundParameters
    .NOTES
    #>

    [CmdletBinding()]
    param(
        # The type of query. This changes the returned hashtable slightly.
        [Parameter(Mandatory = $true)]
        [ValidateSet('New', 'Set')]
        [String]
        $Type,

        # A hashtable of the PSBoundParameters that were passed from the calling function.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $BoundParameters
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        if ($_.Value -is [Hashtable]) {
            Write-Verbose ("{0}|Arguments: {1}:`n{2}" -f $Function_Name, $_.Key, ($_.Value | Format-Table -AutoSize | Out-String).Trim())
        } else {
            Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' '))
        }
    }

    switch ($Type) {
        'New' {
            $Return_Body = @{
                'Settings' = @{
                    'taskName' = $BoundParameters['TaskName']
                }
            }
        }

        'Set' {
            $Return_Body = @{
                'taskName' = $BoundParameters['TaskName']
                'Settings' = @{}
            }
        }
    }

    if ($BoundParameters.ContainsKey('Platform')) {
        $Return_Body['Settings']['platform'] = $BoundParameters['Platform']
    }
    if ($BoundParameters.ContainsKey('TemplateName')) {
        $Return_Body['Settings']['templateName'] = $BoundParameters['TemplateName']
    }
    if ($BoundParameters.ContainsKey('TargetType')) {
        $Return_Body['Settings']['target_type'] = $BoundParameters['TargetType'].ToUpper()
    }
    if ($BoundParameters.ContainsKey('TargetList')) {
        $Return_Body['Settings']['target_list'] = $BoundParameters['TargetList']
    }

    # Update Types.
    if ($BoundParameters.ContainsKey('SecurityUpdates')) {
        $Return_Body['Settings']['security_update'] = $BoundParameters['SecurityUpdates']
    }
    if ($BoundParameters.ContainsKey('ThirdPartyUpdates')) {
        $Return_Body['Settings']['thirdparty_update'] = $BoundParameters['ThirdPartyUpdates']
    }
    if ($BoundParameters.ContainsKey('NonSecurityUpdates')) {
        $Return_Body['Settings']['non_security_update'] = $BoundParameters['NonSecurityUpdates']
    }
    if ($BoundParameters.ContainsKey('DefinitionUpdates')) {
        $Return_Body['Settings']['definition_update'] = $BoundParameters['DefinitionUpdates']
    }
    if ($BoundParameters.ContainsKey('ServicePackUpdates')) {
        $Return_Body['Settings']['servicepack_update'] = $BoundParameters['ServicePackUpdates']
    }
    if ($BoundParameters.ContainsKey('FeaturePackUpdates')) {
        $Return_Body['Settings']['featurepack_update'] = $BoundParameters['FeaturePackUpdates']
    }
    if ($BoundParameters.ContainsKey('Rollups')) {
        $Return_Body['Settings']['rollups'] = $BoundParameters['Rollups']
    }
    if ($BoundParameters.ContainsKey('OptionalUpdates')) {
        $Return_Body['Settings']['optional_updates'] = $BoundParameters['OptionalUpdates']
    }

    # OS/ThirdParty applications.
    if ($BoundParameters.ContainsKey('OSUpdateTarget')) {
        switch ($BoundParameters['OSUpdateTarget']) {
            'PatchAllApplications' {
                $Update_Target = 'Patch All Applications'
            } 'PatchSpecificApplications' {
                $Update_Target = 'Patch Specific Applications'
            } 'PatchAllApplicationsExcept' {
                $Update_Target = 'Patch All Applications Except'
            }
        }
        $Return_Body['Settings']['include_os_app_type'] = $Update_Target
    }
    if ($BoundParameters.ContainsKey('OSUpdateApplication')) {
        $Return_Body['Settings']['os_applications'] = $BoundParameters['OSUpdateApplication']
    }
    if ($BoundParameters.ContainsKey('ThirdPartyUpdateTarget')) {
        switch ($BoundParameters['ThirdPartyUpdateTarget']) {
            'PatchAllApplications' {
                $Update_Target = 'Patch All Applications'
            } 'PatchSpecificApplications' {
                $Update_Target = 'Patch Specific Applications'
            } 'PatchAllApplicationsExcept' {
                $Update_Target = 'Patch All Applications Except'
            }
        }
        $Return_Body['Settings']['include_tp_app_type'] = $Update_Target
    }
    if ($BoundParameters.ContainsKey('ThirdPartyUpdateApplication')) {
        $Return_Body['Settings']['tp_applications'] = $BoundParameters['ThirdPartyUpdateApplication']
    }

    # Notification Parameters.
    if ($BoundParameters.ContainsKey('StatusReportNotification') -and $BoundParameters['StatusReportNotification']) {
        $Return_Body['Settings']['report_notify_enable'] = $true
    }
    if ($BoundParameters.ContainsKey('StatusReportDuration')) {
        $Return_Body['Settings']['report_notify_duration'] = $BoundParameters['StatusReportDuration']
    }
    if ($BoundParameters.ContainsKey('StatusReportAttachment') -and $BoundParameters['StatusReportAttachment']) {
        $Return_Body['Settings']['NeedReportAttachment'] = $true
    }
    if ($BoundParameters.ContainsKey('StatusReportFormat')) {
        $Return_Body['Settings']['attachmentFormatForReport'] = $BoundParameters['StatusReportFormat'].ToLower()
    }
    if ($BoundParameters.ContainsKey('FailureReportNotification') -and $BoundParameters['FailureReportNotification']) {
        $Return_Body['Settings']['failure_notify_enable'] = $true
    }
    if ($BoundParameters.ContainsKey('FailureReportDuration')) {
        $Return_Body['Settings']['failure_notify_duration'] = $BoundParameters['FailureReportDuration']
    }
    if ($BoundParameters.ContainsKey('FailureReportAttachment') -and $BoundParameters['FailureReportAttachment']) {
        $Return_Body['Settings']['NeedFailureAttachment'] = $true
    }
    if ($BoundParameters.ContainsKey('FailureReportFormat')) {
        $Return_Body['Settings']['attachmentFormatForFailure'] = $BoundParameters['FailureReportFormat'].ToLower()
    }
    if ($BoundParameters.ContainsKey('NotificationEmail')) {
        $Return_Body['Settings']['email'] = $BoundParameters['NotificationEmail']
    }

    # Other parameters.
    if ($BoundParameters.ContainsKey('DelayDeploymentByApprovedTime')) {
        $Return_Body['Settings']['delay_deployment_by_approved_time'] = $BoundParameters['DelayDeploymentByApprovedTime']
    }
    if ($BoundParameters.ContainsKey('DelayDeploymentByReleasedTime')) {
        $Return_Body['Settings']['delay_deployment_by_released_time'] = $BoundParameters['DelayDeploymentByReleasedTime']
    }
    if ($BoundParameters.ContainsKey('Description')) {
        $Return_Body['Settings']['description'] = $BoundParameters['Description']
    }
    if ($BoundParameters.ContainsKey('ExpiryTime')) {
        $Return_Body['Settings']['EXPIRY_TIME'] = Get-Date -Date $BoundParameters['ExpiryTime'] -Format 'MM/dd/yyyy, HH:mm'
    }

    $Return_Body
}
