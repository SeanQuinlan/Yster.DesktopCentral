function Set-DCAPDTask {
    <#
    .SYNOPSIS
        Modifies an existing APD task.
    .DESCRIPTION
        Changes an existing APD task with the supplied parameters.

        The following parameters are required:
        - TaskName
        - TargetType
        - TargetList

        NOTE: Most of the values are case-sensitive, so it's easier to just assume all parameters need case-sensitive values.
    .EXAMPLE
        Set-DCAPDTask -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -TaskName 'APD Task 1' -TargetType REMOTE_OFFICE -TargetList 'Local Office' -OptionalUpdates $true

        Modifies the APD task with the name "APD Task 1" and sets the OptionalUpdates setting to true.
    .NOTES
        https://www.manageengine.com/patch-management/api/modify-apd-task.html

        Example body from website:
        {
            "taskname":"windows create task",                       //This is a Mandatory Field
            "settings": {
                "templateName":"Deploy any time at the earliest",
                "target_type":"REMOTE_OFFICE",                      //This is a Mandatory Field and the target type can be (REMOTE_OFFICE,CUSTOM_GROUP,DOMAIN)
                "target_list":"Local Office"                        //This is a Mandatory Field
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
        [Parameter(Mandatory = $false)]
        [ValidateSet('Windows', 'Mac', 'Linux')]
        [String]
        $Platform,

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

        # Whether to skip the SSL certificate check.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $SkipCertificateCheck,

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

        # The name of the APD Task to modify.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TaskName,

        # The name of the deployment template.
        # NOTE: This value is case-sensitive.
        [Parameter(Mandatory = $false)]
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
        $API_Path = 'patch/modifyAPDTask'
        $Body = Get-APDBody -Type 'Set' -BoundParameters $PSBoundParameters

        $Query_Parameters = @{
            'AuthToken'            = $AuthToken
            'HostName'             = $HostName
            'APIPath'              = $API_Path
            'Method'               = 'POST'
            'SkipCertificateCheck' = $SkipCertificateCheck
            'Body'                 = $Body
        }

        $ShouldProcess_Statement = New-Object -TypeName 'System.Text.StringBuilder'
        [void]$ShouldProcess_Statement.AppendLine(('Modify APD task "{0}" with these parameters:' -f $Query_Parameters['Body']['taskName']))
        [void]$ShouldProcess_Statement.AppendLine(($Query_Parameters['Body']['Settings'] | ConvertTo-Json))

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
