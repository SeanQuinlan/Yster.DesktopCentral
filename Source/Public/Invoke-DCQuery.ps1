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
        # The hostname of the Desktop Central server.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $HostName,

        # The port of the Desktop Central server.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Port,

        # The API path.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $APIPath,

        # The REST Method to use.
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST')]
        [String]
        $Method,

        # The message body.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Body,

        # The AuthToken for the API.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AuthToken
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    $API_Version = '1.3'
    $API_Uri = 'http://{0}:{1}/api/{2}/{3}' -f $HostName, $Port, $API_Version, $APIPath

    try {
        $API_Parameters = @{
            'Uri'         = $API_Uri
            'Method'      = $Method
            'ContentType' = 'application/json'
        }
        if ($PSBoundParameters.ContainsKey('Body')) {
            $API_Parameters['Body'] = $Body | ConvertTo-Json
        }
        if ($PSBoundParameters.ContainsKey('AuthToken')) {
            $API_Parameters['Header'] = @{
                'Authorization' = $AuthToken
            }
        }

        try {
            $REST_Response = Invoke-RestMethod @API_Parameters
            Write-Verbose ('{0}|Response status: {1}' -f $Function_Name, $REST_Response.status)

            switch ($REST_Response.status) {
                'error' {
                    $Terminating_ErrorRecord_Parameters = @{
                        'Exception'    = 'System.UnauthorizedAccessException'
                        'ID'           = 'DC-AuthenticationError-{0}' -f $REST_Response.error_code
                        'Category'     = 'AuthenticationError'
                        'TargetObject' = $API_Uri
                        'Message'      = $REST_Response.error_description
                    }
                    $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                    $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
                }
                'success' {
                    $Message_Type = $REST_Response.message_type
                    # Return the relevant message_response child object
                    $REST_Response.message_response.$Message_Type | Add-CalculatedTime | ConvertTo-SortedPSObject
                }
            }
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
