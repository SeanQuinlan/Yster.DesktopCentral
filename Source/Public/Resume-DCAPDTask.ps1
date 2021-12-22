function Resume-DCAPDTask {
    <#
    .SYNOPSIS
        Resumes an APD task.
    .DESCRIPTION
        Resumes the APD task with the supplied name.

        NOTE: The task name is case-sensitive.
    .EXAMPLE
        Resume-DCAPDTask -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -TaskName 'APDTask1'

        Resumes the APD task with the name "APDTask1".
    .NOTES
        https://www.manageengine.com/patch-management/api/resume-apd-task.html
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

        # Whether to skip the SSL certificate check.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $SkipCertificateCheck,

        # The name of the APD Task to resume.
        # NOTE: This value is case-sensitive.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TaskName
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'patch/resumeAPDTask'
        $Query_Parameters = @{
            'AuthToken'            = $AuthToken
            'HostName'             = $HostName
            'APIPath'              = $API_Path
            'Method'               = 'POST'
            'SkipCertificateCheck' = $SkipCertificateCheck
        }

        $ShouldProcess_Statement = New-Object -TypeName 'System.Text.StringBuilder'
        [void]$ShouldProcess_Statement.AppendLine(('Resume APD task: {0}' -f $TaskName))

        $Whatif_Statement = $ShouldProcess_Statement.ToString().Trim()
        $Confirm_Statement = ('Are you sure you want to perform this action?', $Whatif_Statement) -join [Environment]::NewLine
        if ($PSCmdlet.ShouldProcess($Whatif_Statement, $Confirm_Statement, 'Confirm')) {
            Write-Verbose ('{0}|Calling Invoke-DCQuery' -f $Function_Name)

            # NOTE: As of v10.1.2127.12 of Desktop Central, the API returns error "Problem has  occurred while resuming the task" when resuming any task.
            # But the APD task is actually resumed successfully. So we catch that error here and return a good status to make the user experience better.
            try {
                $Query_Return = Invoke-DCQuery @Query_Parameters
                $Query_Return
            } catch {
                if ($_.Exception.Message -eq 'Problem has  occurred while resuming the task') {
                    [pscustomobject]@{
                        'status' = 'task has been resumed successfully'
                    }
                } else {
                    throw $_
                }
            }
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
