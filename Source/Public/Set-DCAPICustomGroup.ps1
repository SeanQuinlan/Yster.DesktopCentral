function Set-DCAPICustomGroup {
    <#
    .SYNOPSIS
        Modifies a custom group and sets some properties.
    .DESCRIPTION
        Sets 3 properties for a custom group:
        - The custom group name.
        - The custom group description.
        - The members of the custom group.
    .EXAMPLE
        Set-DCAPICustomGroup -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -GroupID 601 -NewName 'Modified CG1'

        Updates the custom group with the ID 601 and changes the group name to "Modified CG1".
    .EXAMPLE
        Set-DCAPICustomGroup -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -GroupName 'CustomGroup1' -NewDescription "This is the first Custom Group"

        Updates the description of the custom group with the name "CustomGroup1".
    .EXAMPLE
        Set-DCAPICustomGroup -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -GroupName 'CustomGroup1' -ResourceID 1000,1001

        Updates the group memebers of the custom group with the name "CustomGroup1". Any existing group members will be replaced with the above 2 resource IDs.
    .NOTES
    #>

    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'GroupID')]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The ID of the group to modify.
        [Parameter(Mandatory = $true, ParameterSetName = 'GroupID')]
        [ValidateNotNullOrEmpty()]
        [Int]
        $GroupID,

        # The name of the group to modify.
        [Parameter(Mandatory = $true, ParameterSetName = 'GroupName')]
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

        # The new description for the custom group.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $NewDescription,

        # The new name for the custom group.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('NewGroupName')]
        [String]
        $NewName,

        # The Resource ID or IDs that will be set as the members of the group.
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

    try {
        if (-not $NewDescription -and -not $NewName -and -not $ResourceID) {
            Write-Warning "Nothing to set"
            return
        }

        $Common_Parameters = @{
            'AuthToken'            = $AuthToken
            'HostName'             = $HostName
            'SkipCertificateCheck' = $SkipCertificateCheck
        }

        if ($PSBoundParameters.ContainsKey('GroupName')) {
            Write-Verbose ('{0}|Calling Get-DCAPICustomGroup' -f $Function_Name)
            $Group_Lookup = Get-DCAPICustomGroup @Common_Parameters | Where-Object { $_.groupName -eq $GroupName }
            if (-not $Group_Lookup) {
                $Terminating_ErrorRecord_Parameters = @{
                    'Exception'    = 'System.Net.WebException'
                    'ID'           = 'DC-CustomGroupNotFound'
                    'Category'     = 'ObjectNotFound'
                    'TargetObject' = $GroupName
                    'Message'      = 'Unable to find custom group with name: {0}' -f $GroupName
                }
                $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
            }
            $GroupID = $Group_Lookup.groupId
            Write-Verbose ('{0}|Found group with ID: {1}' -f $Function_Name, $GroupID)
        }
        if (-not $PSBoundParameters.ContainsKey('ResourceID')) {
            Write-Verbose ('{0}|Calling Get-DCAPICustomGroup to get group members' -f $Function_Name)
            $Group_Lookup = Get-DCAPICustomGroup @Common_Parameters -GroupID $GroupID
            $ResourceID = $Group_Lookup.groupMembers.resourceId
        }

        $API_Path = 'dcapi/customGroups'
        $API_Body = @{
            'groupId'     = $GroupID
            'resourceIds' = $ResourceID
        }
        if ($PSBoundParameters.ContainsKey('NewName')) {
            $API_Body['groupName'] = $NewName
        }
        if ($PSBoundParameters.ContainsKey('NewDescription')) {
            $API_Body['description'] = $NewDescription
        }
        $API_Header = @{
            'Accept' = 'application/customGroupUpdated.v1+json'
        }
        $Query_Parameters = @{
            'APIPath'     = $API_Path
            'Method'      = 'PUT'
            'Body'        = $API_Body
            'Header'      = $API_Header
            'ContentType' = 'application/customGroupUpdateDetail.v1+json'
        }

        $ShouldProcess_Statement = New-Object -TypeName 'System.Text.StringBuilder'
        [void]$ShouldProcess_Statement.AppendLine('Modify custom group with these parameters:')
        if ($PSBoundParameters.ContainsKey('NewDescription')) {
            [void]$ShouldProcess_Statement.AppendLine(('- New Description: {0}' -f $NewDescription))
        }
        if ($PSBoundParameters.ContainsKey('NewName')) {
            [void]$ShouldProcess_Statement.AppendLine(('- New Name: {0}' -f $NewName))
        }
        if ($PSBoundParameters.ContainsKey('ResourceID')) {
            [void]$ShouldProcess_Statement.AppendLine(('- ResourceIDs: {0}' -f ($ResourceID -join ',')))
        }

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
