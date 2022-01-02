function Add-DCAPICustomGroupMember {
    <#
    .SYNOPSIS
        Adds one or more resources to a custom group.
    .DESCRIPTION
        Updates the custom group specified and adds the relevant resources to that group. A summary object with the custom group ID and name is returned.

        Note: If invalid resource IDs are provided, the invalid IDs will be returned as another property of the summary object.
    .EXAMPLE
        Add-DCAPICustomGroupMember -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -GroupID 601 -ResourceID 301,302,303

        Adds the computers with resource IDs 301, 302 and 303 to the custom group with ID 601.
    .EXAMPLE
        Add-DCAPICustomGroupMember -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -GroupName "All Servers" -ResourceID 301

        Adds computer with ID 301 to the custom group "All Servers".
    .EXAMPLE
        Add-DCAPICustomGroupMember -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C' -GroupName "Windows Servers" -ResourceName SRV1,SRV2

        Adds computers SRV1 and SRV2 to the custom group "Windows Servers".
    .NOTES
    #>

    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'GroupIDResourceID')]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The ID of the group to add members to.
        [Parameter(Mandatory = $true, ParameterSetName = 'GroupIDResourceID')]
        [Parameter(Mandatory = $true, ParameterSetName = 'GroupIDResourceName')]
        [ValidateNotNullOrEmpty()]
        [Int]
        $GroupID,

        # The name of the custom group.
        [Parameter(Mandatory = $true, ParameterSetName = 'GroupNameResourceID')]
        [Parameter(Mandatory = $true, ParameterSetName = 'GroupNameResourceName')]
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

        # The Resource ID or IDs that will be added to the group.
        [Parameter(Mandatory = $true, ParameterSetName = 'GroupIDResourceID')]
        [Parameter(Mandatory = $true, ParameterSetName = 'GroupNameResourceID')]
        [ValidateNotNullOrEmpty()]
        [Int[]]
        $ResourceID,

        # The Resource Name or Names that will be added to the group.
        [Parameter(Mandatory = $true, ParameterSetName = 'GroupIDResourceName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'GroupNameResourceName')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $ResourceName,

        # Whether to skip the SSL certificate check.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $SkipCertificateCheck
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $Common_Parameters = @{
            'AuthToken'            = $AuthToken
            'HostName'             = $HostName
            'SkipCertificateCheck' = $SkipCertificateCheck
        }

        if ($PSBoundParameters.ContainsKey('ResourceName')) {
            Write-Verbose ('{0}|Calling Get-DCAPIComputer' -f $Function_Name)
            $All_Computers = Get-DCAPIComputer @Common_Parameters | Group-Object -Property 'computerName' -AsHashTable

            $Failed_Resource = New-Object -TypeName System.Collections.Generic.List[String]
            foreach ($Resource in $ResourceName) {
                if ($All_Computers[$Resource]) {
                    $ResourceID += $All_Computers[$Resource].computerID
                } else {
                    $Failed_Resource.Add($Resource)
                }
            }

            if ($Failed_Resource) {
                $Terminating_ErrorRecord_Parameters = @{
                    'Exception'    = 'System.Exception'
                    'ID'           = 'DC-ResourceNameNotFound'
                    'Category'     = 'ObjectNotFound'
                    'TargetObject' = $ResourceName
                    'Message'      = 'Unable to find ID for resource: {0}' -f ($Failed_Resource -join ',')
                }
                $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
            }
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
        }
        $Existing_Group = Get-DCAPICustomGroup @Common_Parameters -GroupID $GroupID
        $New_GroupMembers = ($Existing_Group.groupMembers.resourceId -as [Int[]]) + $ResourceID

        $ShouldProcess_Statement = New-Object -TypeName 'System.Text.StringBuilder'
        [void]$ShouldProcess_Statement.Append('Add group member')
        if ($ResourceID.Count -gt 1) {
            [void]$ShouldProcess_Statement.Append('s')
        }
        [void]$ShouldProcess_Statement.Append(' "')
        if ($PSBoundParameters.ContainsKey('ResourceName')) {
            [void]$ShouldProcess_Statement.Append(($ResourceName -join ','))
        } else {
            [void]$ShouldProcess_Statement.Append(($ResourceID -join ','))
        }
        [void]$ShouldProcess_Statement.Append(('" to custom group: "{0}" (ID={1}' -f $Existing_Group.groupName, $GroupID))
        [void]$ShouldProcess_Statement.AppendLine(')')

        $Whatif_Statement = $ShouldProcess_Statement.ToString().Trim()
        $Confirm_Statement = ('Are you sure you want to perform this action?', $Whatif_Statement) -join [Environment]::NewLine
        if ($PSCmdlet.ShouldProcess($Whatif_Statement, $Confirm_Statement, 'Confirm')) {
            Write-Verbose ('{0}|Calling Set-DCAPICustomGroup' -f $Function_Name)
            $Query_Return = Set-DCAPICustomGroup @Common_Parameters -GroupID $GroupID -ResourceID $New_GroupMembers -Confirm:$false
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
