function Invoke-DCQuery {
    <#
    .SYNOPSIS
        An internal function to perform the API query and return the relevant results.
    .DESCRIPTION
        A wrapper function that can be called by all the other higher-level functions to peform the actual API query.

        This is an internal function and not meant to be called directly.
    .EXAMPLE
        $Query_Parameters = @{
            'AuthToken' = $AuthToken
            'HostName'  = $HostName
            'Port'      = $Port
            'APIPath'   = 'som/computers/installagent'
            'Method'    = 'POST'
            'Body'      = @{
                'resourceids' = $ResourceID
            }
        }
        Invoke-DCQuery @Query_Parameters
    #>

    [CmdletBinding()]
    param(
        # The API path.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $APIPath,

        # The AuthToken for the API.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken,

        # The message body.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Body,

        # The Content-Type to send.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ContentType = 'application/json',

        # Additional header to add.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Header,

        # The hostname of the Desktop Central server.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $HostName,

        # The REST Method to use.
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST')]
        [String]
        $Method,

        # The port of the Desktop Central server.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Port
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        if ($_.Value -is [Hashtable]) {
            Write-Verbose ("{0}|Arguments: {1}:`n{2}" -f $Function_Name, $_.Key, ($_.Value | Format-Table -AutoSize | Out-String).Trim())
        } else {
            Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' '))
        }
    }

    if ($APIPath -match '^dcapi') {
        $API_Uri = 'http://{0}:{1}/{2}' -f $HostName, $Port, $APIPath
        $NewAPI = $true
    } else {
        $API_Version = '1.3'
        $API_Uri = 'http://{0}:{1}/api/{2}/{3}' -f $HostName, $Port, $API_Version, $APIPath
    }

    try {
        $global:API_Parameters = @{
            'Uri'         = $API_Uri
            'Method'      = $Method
            'ContentType' = $ContentType
        }
        if ($PSBoundParameters.ContainsKey('Body')) {
            $API_Parameters['Body'] = $Body | ConvertTo-Json
        }
        if ($PSBoundParameters.ContainsKey('AuthToken')) {
            $API_Parameters['Header'] = @{
                'Authorization' = $AuthToken
            }
        }
        if ($PSBoundParameters.ContainsKey('Header')) {
            $API_Parameters['Header'] += $Header
        }

        try {
            $global:REST_Response = Invoke-RestMethod @API_Parameters

            if ($NewAPI) {
                # The new API (host:port/dcapi) returns the objects directly, rather than as a sub-property
                Write-Verbose ('{0}|Response items returned: {1}' -f $Function_Name, $REST_Response.Count)
                $Return_Object = $REST_Response
            } else {
                Write-Verbose ('{0}|Response status: {1}' -f $Function_Name, $REST_Response.status)
                switch ($REST_Response.status) {
                    'error' {
                        $Terminating_ErrorRecord_Parameters = @{
                            'Exception'    = 'System.InvalidOperationException'
                            'ID'           = 'DC-REST-Error-{0}' -f $REST_Response.error_code
                            'Category'     = 'InvalidResult'
                            'TargetObject' = $API_Uri
                            'Message'      = $REST_Response.error_description
                        }
                        $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                        $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
                    }
                    'success' {
                        $Message_Type = $REST_Response.message_type
                        # Return the relevant message_response child object
                        $Return_Object = $REST_Response.message_response.$Message_Type
                    }
                }
            }
            $Return_Object | Add-CalculatedProperty | ConvertTo-SortedPSObject
        } catch [System.Net.WebException] {
            if ($_.ErrorDetails.Message) {
                $Returned_ErrorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
            }

            switch -Wildcard ($_.Exception.Message) {
                'The remote server returned an error: (401) Unauthorized*' {
                    $Terminating_ErrorRecord_Parameters = @{
                        'Exception'    = 'System.Net.WebException'
                        'ID'           = 'DC-Unauthorized-{0}' -f $Returned_ErrorDetails.ErrorCode
                        'Category'     = 'SecurityError'
                        'TargetObject' = $API_Uri
                        'Message'      = $Returned_ErrorDetails.ErrorMsg
                    }
                    $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                    $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
                }
                'The remote name could not be resolved*' {
                    $Terminating_ErrorRecord_Parameters = @{
                        'Exception'    = 'System.Net.WebException'
                        'ID'           = 'DC-NameResolutionFailure'
                        'Category'     = 'ResourceUnavailable'
                        'TargetObject' = $API_Uri
                        'Message'      = $_
                    }
                    $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                    $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
                }
                default {
                    $Terminating_ErrorRecord_Parameters = @{
                        'Exception'    = 'System.Net.WebException'
                        'ID'           = 'DC-REST-Error-{0}' -f $Returned_ErrorDetails.ErrorCode
                        'Category'     = 'InvalidResult'
                        'TargetObject' = $API_Uri
                        'Message'      = $Returned_ErrorDetails.ErrorMsg
                    }
                    $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                    $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
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
