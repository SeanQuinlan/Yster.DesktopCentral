function Get-DCRemoteOffice {
    <#
    .SYNOPSIS
        Gets a list of remote offices, with details.
    .DESCRIPTION
        Outputs a number of details about each remote office.
    .EXAMPLE
        Get-DCRemoteOffice -HostName DCSERVER -AuthToken '47A1157A-7AAC-4660-XXXX-34858F3A001C'

        Returns all remote office details.
    .NOTES
        https://www.manageengine.com/products/desktop-central/api/api-som-remoteoffices.html
    #>

    [CmdletBinding()]
    param(
        # The AuthToken for the Desktop Central server API.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The hostname of the Desktop Central server.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $HostName,

        # The page of results to return.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Page,

        # The port of the Desktop Central server.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Port = 8020,

        # Limit the number of results that are returned.
        # The default is to return all results.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Alias('Limit', 'PageLimit')]
        [Int]
        $ResultSize = 0
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $PSBoundParameters['ResultSize'] = $ResultSize
        $API_Path = Add-Filters -BoundParameters $PSBoundParameters -BaseURL 'som/remoteoffice'
        $Query_Parameters = @{
            'AuthToken' = $AuthToken
            'HostName'  = $HostName
            'Port'      = $Port
            'APIPath'   = $API_Path
            'Method'    = 'GET'
        }
        Write-Verbose ('{0}|Calling Invoke-DCQuery' -f $Function_Name)
        $Query_Return = Invoke-DCQuery @Query_Parameters
        $Query_Return

    } catch {
        if ($_.FullyQualifiedErrorId -match '^DC-') {
            $Terminating_ErrorRecord = New-DefaultErrorRecord -InputObject $_
            $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
        } else {
            throw
        }
    }
}
