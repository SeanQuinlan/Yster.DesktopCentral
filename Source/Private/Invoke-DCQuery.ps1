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

        # The hostname/FQDN/IP address of the Desktop Central server.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $HostName,

        # The REST Method to use.
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST', 'PUT')]
        [String]
        $Method,

        # The number of results that are returned.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $ResultSize,

        # Whether to skip the SSL certificate check.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $SkipCertificateCheck
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        if ($_.Value -is [Hashtable]) {
            Write-Verbose ("{0}|Arguments: {1}:`n{2}" -f $Function_Name, $_.Key, ($_.Value | Format-Table -AutoSize | Out-String).Trim())
        } else {
            Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' '))
        }
    }

    try {
        if ($HostName -notmatch '^https?\:\/\/') {
            $HostName = 'https://{0}' -f $HostName
        }
        if ($HostName -match 'https\:\/\/') {
            $Port = 8383
        } else {
            $Port = 8020
        }
        if ($APIPath -match '^dcapi') {
            $API_Uri = '{0}:{1}/{2}' -f $HostName, $Port, $APIPath
            $NewAPI = $true
        } else {
            $API_Uri = '{0}:{1}/api/1.4/{2}' -f $HostName, $Port, $APIPath
        }

        $API_Parameters = @{
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
            $Return_Object = New-Object -TypeName 'System.Collections.Generic.List[Object]'
            $Page = 1
            $Results_To_Return = $ResultSize
            $Results_Gathered = 0
            $All_Results_Returned = $false

            while (-not $All_Results_Returned) {
                if (($ResultSize -eq 0) -or ($ResultSize -gt $Max_Query_Results)) {
                    $Current_Limit = $Max_Query_Results
                } else {
                    $Current_Limit = $ResultSize
                }

                if (-not $NewAPI) {
                    if ($API_Uri -match '\?') {
                        $Initial_Character = '&'
                    } else {
                        $Initial_Character = '?'
                    }
                    $API_Parameters['Uri'] = '{0}{1}page={2}&pagelimit={3}' -f $API_Uri, $Initial_Character, $Page, $Current_Limit
                } else {
                    $API_Parameters['Uri'] = $API_Uri
                }
                Write-Verbose ('{0}|Uri: {1}' -f $Function_Name, $API_Parameters['Uri'])

                if ($PSEdition -eq 'Core') {
                    $API_Parameters['SkipCertificateCheck'] = $SkipCertificateCheck
                    $REST_Response = Invoke-RestMethod @API_Parameters
                } else {
                    if ($SkipCertificateCheck) {
                        Write-Verbose ('{0}|Disabling SSL check' -f $Function_Name)
                        $SavedCertificatePolicy = [System.Net.ServicePointManager]::CertificatePolicy
                        [System.Net.ServicePointManager]::CertificatePolicy = New-Object -TypeName TrustAllCertsPolicy
                    }
                    $REST_Response = Invoke-RestMethod @API_Parameters
                    if ($SavedCertificatePolicy) {
                        [System.Net.ServicePointManager]::CertificatePolicy = $SavedCertificatePolicy
                    }
                }

                if ($NewAPI) {
                    # The new API (host:port/dcapi) returns the objects directly, rather than as a sub-property
                    Write-Verbose ('{0}|Response items returned: {1}' -f $Function_Name, @($REST_Response).Count)
                    $Return_Object = $REST_Response
                    $All_Results_Returned = $true
                } else {
                    Write-Verbose ('{0}|Response status [Page {1}]: {2}' -f $Function_Name, $Page, $REST_Response.status)
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
                            if ($Results_To_Return -eq 0) {
                                $Results_To_Return = $REST_Response.message_response.total
                            }
                            $Message_Type = $REST_Response.message_type
                            # Return the relevant message_response child object
                            $Return_Object.AddRange(@($REST_Response.message_response.$Message_Type))
                            $Results_Gathered = $Results_Gathered + $REST_Response.message_response.$Message_Type.Count
                            # If zero responses are returned, then there's no more to get
                            if (($Results_Gathered -ge $Results_To_Return) -or ($REST_Response.message_response.total -eq 0)) {
                                $All_Results_Returned = $true
                            }
                        }
                    }
                }
                $Page++
            }

            $Return_Object | Add-CalculatedProperty | ConvertTo-SortedPSObject
        } catch {
            if ($_.ErrorDetails.Message) {
                if ($PSEdition -eq 'Core') {
                    $ErrorType = $_.Exception.GetType().BaseType.FullName
                } else {
                    $ErrorType = $_.Exception.GetType().FullName
                }

                $InnerException = $_
                $Returned_ErrorDetails = $InnerException.ErrorDetails.Message | ConvertFrom-Json
                switch -Wildcard ($InnerException.Exception.Message) {
                    'The remote server returned an error: (401) Unauthorized*' {
                        $Terminating_ErrorRecord_Parameters = @{
                            'Exception'      = $ErrorType
                            'ID'             = 'DC-Unauthorized-{0}' -f $Returned_ErrorDetails.ErrorCode
                            'Category'       = 'SecurityError'
                            'TargetObject'   = $API_Uri
                            'Message'        = $Returned_ErrorDetails.ErrorMsg
                            'InnerException' = $InnerException.Exception
                        }
                        $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                        $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
                    }
                    'The remote name could not be resolved*' {
                        $Terminating_ErrorRecord_Parameters = @{
                            'Exception'      = $ErrorType
                            'ID'             = 'DC-NameResolutionFailure'
                            'Category'       = 'ResourceUnavailable'
                            'TargetObject'   = $API_Uri
                            'Message'        = $_
                            'InnerException' = $InnerException.Exception
                        }
                        $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                        $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
                    }
                    # When trying to set a custom group and providing only invalid resource IDs, the resulting JSON doesn't contain ErrorCode and ErrorMsg properties.
                    'The remote server returned an error: (412)*' {
                        $Terminating_ErrorRecord_Parameters = @{
                            'Exception'      = $ErrorType
                            'ID'             = 'DC-HTTP-Error-{0}' -f $InnerException.Exception.Response.StatusDescription
                            'Category'       = 'InvalidResult'
                            'TargetObject'   = $API_Uri
                            'Message'        = $InnerException.ErrorDetails.Message
                            'InnerException' = $InnerException.Exception
                        }
                        $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                        $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
                    }
                    'The remote server returned an error: (500) Internal Server Error*' {
                        $Terminating_ErrorRecord_Parameters = @{
                            'Exception'      = $ErrorType
                            'ID'             = 'DC-HTTP-Error-{0}' -f $InnerException.Exception.Response.StatusDescription
                            'Category'       = 'InvalidResult'
                            'TargetObject'   = $API_Uri
                            'Message'        = $InnerException.Exception.Message
                            'InnerException' = $InnerException.Exception
                        }
                        $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                        $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
                    }
                    default {
                        $Terminating_ErrorRecord_Parameters = @{
                            'Exception'      = $ErrorType
                            'ID'             = 'DC-REST-Error-{0}' -f $Returned_ErrorDetails.ErrorCode
                            'Category'       = 'InvalidResult'
                            'TargetObject'   = $API_Uri
                            'Message'        = $Returned_ErrorDetails.ErrorMsg
                            'InnerException' = $InnerException.Exception
                        }
                        $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                        $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
                    }
                }
            } else {
                $Terminating_ErrorRecord_Parameters = @{
                    'Exception'      = $ErrorType
                    'ID'             = 'DC-ConnectionError'
                    'Category'       = 'InvalidResult'
                    'TargetObject'   = $API_Uri
                    'Message'        = $_.Exception.Message
                    'InnerException' = $_.Exception
                }
                $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
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
