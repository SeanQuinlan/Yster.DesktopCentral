function Get-DCAPIToken {
    <#
    .SYNOPSIS
        Authenticates to the Desktop Central server and retrieves an API Token.
    .DESCRIPTION
        Connects to the authentication URL in order to retrieve an API Token.

        If two-factor auth has been enabled on the server, the OTP parameter will be required.

        Provide credentials in the form of "DOMAIN\USERNAME" for AD authentication, or just "USERNAME" for local authentication.
    .EXAMPLE
        Get-DCAPIToken -HostName DCSERVER -Credential 'DOMAIN\User'

        Connect as the AD user "DOMAIN\User" with no OTP. You will be prompted to enter the password for the user.
    .EXAMPLE
        $Creds = Get-Credential
        Get-DCAPIToken -HostName DCSERVER -Credential $Creds -OTP 123456

        Gets the user credentials first, then connects to the Desktop Central server with those credentials and the OTP from the app.
    .NOTES
        https://www.manageengine.com/products/desktop-central/api/index.html
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
        $Credential,

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

        # The OTP from the Authenticator app.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $OTP,

        # Whether to skip the SSL certificate check.
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $SkipCertificateCheck
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    try {
        $Base64_Password = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Credential.GetNetworkCredential().Password))
        $API_Path = 'desktop/authentication'
        $Auth_Options = New-Object -TypeName 'System.Collections.Generic.List[String]'
        if ($Credential.UserName -match '\\') {
            Write-Verbose ('{0}|Domain authentication used' -f $Function_Name)
            $DomainName = ($Credential.UserName -split '\\')[0].ToLower()
            $UserName = ($Credential.UserName -split '\\')[1]
            $Auth_Options.Add('username={0}' -f $UserName)
            $Auth_Options.Add('domainName={0}' -f $DomainName)
            $Auth_Options.Add('password={0}' -f $Base64_Password)
            $Auth_Options.Add('auth_type=ad_authentication')
        } else {
            Write-Verbose ('{0}|Local authentication used' -f $Function_Name)
            $Auth_Options.Add('username={0}' -f $Credential.UserName)
            $Auth_Options.Add('password={0}' -f $Base64_Password)
            $Auth_Options.Add('auth_type=local_authentication')
        }
        $API_Path += '?{0}' -f ($Auth_Options -join '&')

        $Query_Parameters = @{
            'HostName'             = $HostName
            'APIPath'              = $API_Path
            'Method'               = 'POST'
            'SkipCertificateCheck' = $SkipCertificateCheck
        }
        Write-Verbose ('{0}|Calling Invoke-DCQuery' -f $Function_Name)
        $Query_Return = Invoke-DCQuery @Query_Parameters

        if ($Query_Return.two_factor_data.is_TwoFactor_Enabled) {
            Write-Verbose ('{0}|Two Factor Auth is enabled' -f $Function_Name)
            if ($Query_Return.two_factor_data.google_authenticator_key) {
                $Terminating_ErrorRecord_Parameters = @{
                    'Exception'    = 'System.ArgumentException'
                    'ID'           = 'DC-AuthenticatorNotConfigured'
                    'Category'     = 'AuthenticationError'
                    'TargetObject' = $API_Path
                    'Message'      = 'OTP required but Authenticator is not yet configured'
                }
                $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
                $PSCmdlet.ThrowTerminatingError($Terminating_ErrorRecord)
            } elseif ($Query_Return.two_factor_data.message -eq 'Google authentication already created for this user. Validate OTP') {
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
                    'uid' = $Query_Return.two_factor_data.unique_userID
                    'otp' = "$OTP"
                }
                $OTP_Query_Parameters = @{
                    'HostName' = $HostName
                    'APIPath'  = $OTP_Query_URL
                    'Method'   = 'POST'
                    'Body'     = $OTP_Query_Body
                }
                Write-Verbose ('{0}|Calling Invoke-DCQuery for OTP' -f $Function_Name)
                $Query_Return = Invoke-DCQuery @OTP_Query_Parameters
            }
        }

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
