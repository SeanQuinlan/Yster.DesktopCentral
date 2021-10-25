function Set-DCCustomGroup {
    <#
    .SYNOPSIS
        Modifies a custom group.
    .DESCRIPTION
        Sets some properties on a custom group.

        The GroupID and ResourceID parameters are required.
    .EXAMPLE
        Set-DCCustomGroup -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -GroupID 601 -ResourceID 301 -GroupName 'Modified CG1'

        Updates the custom group with the ID 601 and changes the group members to ResourceID 301 and the group name to "Modified CG1"
    .NOTES

    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The description of the custom group.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Description,

        # The ID of the group to modify.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $GroupID,

        # The name of the custom group.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

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

        # The Resource ID or IDs that will be set as the members of the group.
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
        $API_Path = 'dcapi/customGroups'
        $API_Body = @{
            'groupId'     = $GroupID
            'resourceIds' = $ResourceID
        }
        if ($PSBoundParameters.ContainsKey('GroupName')) {
            $API_Body['groupName'] = $GroupName
        }
        if ($PSBoundParameters.ContainsKey('Description')) {
            $API_Body['description'] = $Description
        }
        $API_Header = @{
            'Accept' = 'application/customGroupUpdated.v1+json'
        }
        $Query_Parameters = @{
            'AuthToken'            = $AuthToken
            'HostName'             = $HostName
            'APIPath'              = $API_Path
            'Method'               = 'PUT'
            'SkipCertificateCheck' = $SkipCertificateCheck
            'Body'                 = $API_Body
            'Header'               = $API_Header
            'ContentType'          = 'application/customGroupUpdateDetail.v1+json'
        }

        $Confirm_Header = New-Object -TypeName 'System.Text.StringBuilder'
        [void]$Confirm_Header.AppendLine('Confirm')
        [void]$Confirm_Header.AppendLine('Are you sure you want to perform this action?')

        $Remove_ShouldProcess = New-Object -TypeName 'System.Text.StringBuilder'
        [void]$Remove_ShouldProcess.AppendLine(('Modify custom group with these parameters:'))
        [void]$Remove_ShouldProcess.AppendLine(($API_Body | ConvertTo-Json))

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
