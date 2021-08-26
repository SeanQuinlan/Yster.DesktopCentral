function Get-DCAPIToken {
    <#
    .SYNOPSIS
        Authenticates to the Desktop Central server and retrieves an API Token.
    .DESCRIPTION

    .EXAMPLE

    .NOTES

    #>

    [CmdletBinding()]
    param(
        # The credential to log onto Desktop Central.
        # This credential can be provided in the form of a username, DOMAIN\username or as a PowerShell credential object.
        # In the case of a username or DOMAIN\username, you will be prompted to supply the password.
        # Some examples of using this property are:
        #
        # -Credential jsmith
        # -Credential 'CONTOSO\jsmith'
        #
        # $Creds = Get-Credential
        # -Credential $Creds
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        # The hostname of the Desktop Central server.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $HostName,

        # The port of the Desktop Central server.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Port = 8020,

        # The OTP from the Authenticator app.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $OTP
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $Base64_Password = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Credential.GetNetworkCredential().Password))
        if ($Credential.UserName -match '\\') {
            Write-Verbose ('{0}|Domain authentication used' -f $Function_Name)
            $DomainName = ($Credential.UserName -split '\\')[0].ToLower()
            $UserName = ($Credential.UserName -split '\\')[1]
            $Query_URL = 'desktop/authentication?username={0}&password={1}&auth_type=ad_authentication&domainName={2}' -f $UserName, $Base64_Password, $DomainName
        } else {
            Write-Verbose ('{0}|Local authentication used' -f $Function_Name)
            $Query_URL = 'desktop/authentication?username={0}&password={1}&auth_type=local_authentication' -f $Credential.UserName, $Base64_Password
        }

        $Query_Parameters = @{
            'HostName' = $HostName
            'Port'     = $Port
            'APIPath'  = $Query_URL
            'Method'   = 'POST'
        }
        Write-Verbose ('{0}|Calling Invoke-DCQuery for Authentication' -f $Function_Name)
        $Query_Return = Invoke-DCQuery @Query_Parameters

        $Result_To_Return = @{
            'Raw'                = $Query_Return
            'AuthToken'          = $Query_Return.authentication.auth_data.auth_token
            'IsTwoFactorEnabled' = $Query_Return.authentication.two_factor_data.is_TwoFactor_Enabled
        }

        if ($Result_To_Return['IsTwoFactorEnabled']) {
            Write-Verbose ('{0}|Two Factor Auth is enabled' -f $Function_Name)
            if ($Query_Return.authentication.two_factor_data.google_authenticator_key) {
                $Terminating_ErrorRecord_Parameters = @{
                    'Exception'    = 'System.ArgumentException'
                    'ID'           = 'DC-AuthenticatorNotConfigured'
                    'Category'     = 'AuthenticationError'
                    'TargetObject' = $Query_URL
                    'Message'      = 'OTP required but Authenticator is not yet configured'
                }
                $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
            } elseif ($Query_Return.authentication.two_factor_data.message -eq 'Google authentication already created for this user. Validate OTP') {
                if (-not $OTP) {
                    $Terminating_ErrorRecord_Parameters = @{
                        'Exception'    = 'System.ArgumentException'
                        'ID'           = 'DC-OTPNotProvided'
                        'Category'     = 'AuthenticationError'
                        'TargetObject' = $Query_URL
                        'Message'      = 'OTP required by server but not provided'
                    }
                    $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                    $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
                }

                $OTP_Query_URL = 'desktop/authentication/otpValidate'
                $OTP_Query_Body = @{
                    'uid' = $Query_Return.authentication.two_factor_data.unique_userID
                    'otp' = "$OTP"
                }
                $OTP_Query_Parameters = @{
                    'HostName' = $HostName
                    'Port'     = $Port
                    'APIPath'  = $OTP_Query_URL
                    'Method'   = 'POST'
                    'Body'     = $OTP_Query_Body
                }
                Write-Verbose ('{0}|Calling Invoke-DCQuery for OTP' -f $Function_Name)
                $OTP_Query_Return = Invoke-DCQuery @OTP_Query_Parameters
                $Result_To_Return['AuthToken'] = $OTP_Query_Return.authentication.auth_data.auth_token
            }
        }

        $Result_To_Return | ConvertTo-SortedPSObject

    } catch {
        if ($_.FullyQualifiedErrorId -match '^DC-') {
            $Terminating_ErrorRecord = New-DefaultErrorRecord -InputObject $_
            $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
        } else {
            throw
        }
    }
}
