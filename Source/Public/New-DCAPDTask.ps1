function New-DCAPDTask {
    <#
    .SYNOPSIS
        Creates a new APD task.
    .DESCRIPTION
        Adds a new APD task with the supplied properties.

        The following parameters are required:
        - TaskName
        - Platform
        - TemplateName
        - TargetType
        - TargetList
        - At least one update type from this list: SecurityUpdates, NonSecurityUpdates, ThirdPartyUpdates, DefinitionUpdates, ServicePackUpdates, FeaturePackUpdates, Rollups, OptionalUpdates

        The remaining paramters are optional, however some of them will be ignored if supporting paramters are not also included. For example, NotificationEmail will be ignored if either StatusReportNotification or FailureReportNotification is not provided.

        NOTE: Most of the values are case-sensitive, so it's easier to just assume all parameters need case-sensitive values.
    .EXAMPLE
        New-DCAPDTask -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -TaskName 'APD Task 1' -Platform 'Windows' -TemplateName 'Force reboot excluding servers' -TargetType REMOTE_OFFICE -TargetList 'Local Office' -SecurityUpdates $true

        Create the APD task with the name "APD Task 1" and the parameters specified.
    .NOTES
        https://www.manageengine.com/patch-management/api/create-apd-task.html

        Example JSON body from website:
        {
            "settings": {
                "taskName":"windows create task", 	    //This is a Mandatory Field
                "description":"task for windows",
                "platform":"Windows", 				    //This is a Mandatory Field
                "security_update":"true",			    //This is applicable for all 3 platforms
                "non_security_update":"true",		    //This is applicable only for Windows & Mac
                "thirdparty_update":"true",			    //This is applicable for all 3 platforms
                "definition_update":"true",			    //This is applicable only for Windows
                "servicepack_update":"true",		    //This is applicable only for Windows
                "featurepack_update":"true",		    //This is applicable only for Windows
                "rollups":"true",					    //This is applicable only for Windows
                "optional_updates":"true",
                "include_tp_app_type":"Patch Specific Applications",
                "include_os_app_type":"Patch All Applications Except",
                "os_applications":"Windows Defender x64",
                "tp_applications":"Notepad++",
                "delay_deployment_by_approved_time/delay_deployment_by_released_time":"5",
                "EXPIRY_TIME":"08/29/2018, 00:00",
                "templateName":"Force reboot excluding servers",	//This is a Mandatory Field
                "target_type":"REMOTE_OFFICE",						//This is a Mandatory Field and the target type can be (REMOTE_OFFICE,CUSTOM_GROUP,DOMAIN)
                "target_list":"Local Office",						//This is a Mandatory Field
                "failure_notify_enable":"false",
                "failure_notify_duration":"1",
                "NeedFailureAttachment":"true",
                "attachmentFormatForFailure":"xls",
                "report_notify_enable":"false",
                "report_notify_duration":"3",
                "NeedReportAttachment":"true",
                "attachmentFormatForReport":"pdf",
                "email":"xx@yy.com"
            }
        }
    #>

    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'DelayByReleased')]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # Install Definition updates.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('DefinitionUpdate')]
        [Boolean]
        $DefinitionUpdates,

        # Delay the deployment for this many days after the approved time.
        [Parameter(Mandatory = $false, ParameterSetName = 'DelayByApproved')]
        [ValidateNotNullOrEmpty()]
        [Int]
        $DelayDeploymentByApprovedTime,

        # Delay the deployment for this many days after the released time.
        [Parameter(Mandatory = $false, ParameterSetName = 'DelayByReleased')]
        [ValidateNotNullOrEmpty()]
        [Int]
        $DelayDeploymentByReleasedTime,

        # The description of the APD task.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Description,

        # The expiry time of the APD task.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [DateTime]
        $ExpiryTime,

        # Attach a detailed report on deployment failures.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Boolean]
        $FailureReportAttachment,

        # How often to notify about failures (in hours).
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $FailureReportDuration,

        # The file format of the deployment failure report.
        [Parameter(Mandatory = $false)]
        [ValidateSet('csv', 'pdf', 'xls')]
        [String]
        $FailureReportFormat,

        # Notify about deployment failures.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Boolean]
        $FailureReportNotification,

        # Install Feature Pack updates.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('FeaturePackUpdate')]
        [Boolean]
        $FeaturePackUpdates,

        # The hostname of the Desktop Central server.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $HostName,

        # Install Non-Security updates.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('NonSecurityUpdate')]
        [Boolean]
        $NonSecurityUpdates,

        # The email address to send the notifications to.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('Email')]
        [String]
        $NotificationEmail,

        # Install Optional updates.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('OptionalUpdate')]
        [Boolean]
        $OptionalUpdates,

        # The Application to patch or exclude, depending on the OS Update Target.
        # NOTE: This value is case-sensitive.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OSUpdateApplication,

        # The target for OS updates.
        [Parameter(Mandatory = $false)]
        [ValidateSet('PatchAllApplications', 'PatchSpecificApplications', 'PatchAllApplicationsExcept')]
        [Alias('OSUpdateType')]
        [String]
        $OSUpdateTarget,

        # The OS platform for the task.
        [Parameter(Mandatory = $true)]
        [ValidateSet('Windows', 'Mac', 'Linux')]
        [String]
        $Platform,

        # The port of the Desktop Central server.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Port = 8020,

        # Install Rollups.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('Rollup')]
        [Boolean]
        $Rollups,

        # Install Security updates.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('SecurityUpdate')]
        [Boolean]
        $SecurityUpdates,

        # Install Service Pack updates.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServicePackUpdate')]
        [Boolean]
        $ServicePackUpdates,

        # Attach a detailed report on deployment status.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Boolean]
        $StatusReportAttachment,

        # How often to notify about deployment status (in hours).
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $StatusReportDuration,

        # The file format of the deployment status report.
        [Parameter(Mandatory = $false)]
        [ValidateSet('csv', 'pdf', 'xls')]
        [String]
        $StatusReportFormat,

        # Notify about deployment status.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Boolean]
        $StatusReportNotification,

        # The type of the target list.
        [Parameter(Mandatory = $true)]
        [ValidateSet('REMOTE_OFFICE', 'CUSTOM_GROUP', 'DOMAIN')]
        [String]
        $TargetType,

        # The list to target the APD task at.
        # NOTE: This value is case-sensitive.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TargetList,

        # The name of the APD Task to create.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TaskName,

        # The name of the deployment template.
        # NOTE: This value is case-sensitive.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TemplateName,

        # Install Third Party updates.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('ThirdPartyUpdate')]
        [Boolean]
        $ThirdPartyUpdates,

        # The Application to patch or exclude, depending on the Third Party Update Target.
        # NOTE: This value is case-sensitive.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ThirdPartyUpdateApplication,

        # The target for Third Party updates.
        [Parameter(Mandatory = $false)]
        [ValidateSet('PatchAllApplications', 'PatchSpecificApplications', 'PatchAllApplicationsExcept')]
        [Alias('ThirdPartyUpdateType')]
        [String]
        $ThirdPartyUpdateTarget
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        # Check that at least one update parameter has been supplied.
        $Update_Supplied = $false
        if ($PSBoundParameters.ContainsKey('SecurityUpdates') -and $SecurityUpdates) {
            # Valid for all 3 platforms.
            $Update_Supplied = $true
        }
        if ($PSBoundParameters.ContainsKey('ThirdPartyUpdates') -and $ThirdPartyUpdates) {
            # Valid for all 3 platforms.
            $Update_Supplied = $true
        }
        if ($PSBoundParameters.ContainsKey('NonSecurityUpdates') -and $NonSecurityUpdates) {
            # Valid for Windows & Mac only.
            if (($Platform -eq 'Windows') -or ($Platform -eq 'Mac')) {
                $Update_Supplied = $true
            }
        }
        if ($PSBoundParameters.ContainsKey('DefinitionUpdates') -and $DefinitionUpdates) {
            # Valid for Windows only.
            if ($Platform -eq 'Windows') {
                $Update_Supplied = $true
            }
        }
        if ($PSBoundParameters.ContainsKey('ServicePackUpdates') -and $ServicePackUpdates) {
            # Valid for Windows only.
            if ($Platform -eq 'Windows') {
                $Update_Supplied = $true
            }
        }
        if ($PSBoundParameters.ContainsKey('FeaturePackUpdates') -and $FeaturePackUpdates) {
            # Valid for Windows only.
            if ($Platform -eq 'Windows') {
                $Update_Supplied = $true
            }
        }
        if ($PSBoundParameters.ContainsKey('Rollups') -and $Rollups) {
            # Valid for Windows only.
            if ($Platform -eq 'Windows') {
                $Update_Supplied = $true
            }
        }
        if ($PSBoundParameters.ContainsKey('OptionalUpdates') -and $OptionalUpdates) {
            # Valid for Windows only.
            if ($Platform -eq 'Windows') {
                $Update_Supplied = $true
            }
        }
        if (-not $Update_Supplied) {
            $Terminating_ErrorRecord_Parameters = @{
                'Exception'    = 'System.Management.Automation.PropertyNotFoundException'
                'ID'           = 'DC-MissingUpdateType'
                'Category'     = 'ObjectNotFound'
                'TargetObject' = $API_Path
                'Message'      = 'At least one update type must be specified.'
            }
            $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
            $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
        }

        $API_Path = 'patch/createAPDTask'
        $Body = Get-APDBody -Type 'New' -BoundParameters $PSBoundParameters

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
        [void]$Remove_ShouldProcess.AppendLine(('Create APD task with these parameters:'))
        [void]$Remove_ShouldProcess.AppendLine(($Query_Parameters['Body']['Settings'] | ConvertTo-Json))

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
