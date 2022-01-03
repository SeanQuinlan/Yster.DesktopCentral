# Yster.DesktopCentral

This is a PowerShell module to interact with ManageEngine's Desktop Central API.

Currently Desktop Central has 2 separate APIs:

* The old v1.3 version of the API - available at /api/1.3
* The newer DCAPI version - available at /dacpi

Only the older version of the API is [documented online](https://www.manageengine.com/products/desktop-central/api/index.html). The newer DCAPI endpoints have been pieced together via documentation sent by Manage Engine, examining the javascript files on the server and through some trial and error.

I have used different prefixes to separate the cmdlets between the API versions:

* All the older API functions use the prefix ```DC```.
* All newer API functions use ```DCAPI```.

## Installation

The module can be installed from the PowerShell gallery, or downloaded from here and loaded manually.

### PowerShell Gallery

```powershell
Install-Module Yster.DesktopCentral -Scope CurrentUser
Import-Module Yster.DesktopCentral
```

### Manually

* Download the zip of this repository via the Code button at the top right.
* Extract the zip file.
* Import the module's psd1 file directly:

```powershell
Import-Module .\Source\Yster.DesktopCentral.psd1
```

## API Key

All cmdlets will require an API key for access. You can obtain this API key via the web interface, or via the ```Get-DCAPIToken``` cmdlet.

### Web Interface

* Log into the Desktop Central Server.
* Go to **Admin - API Explorer**.
* Under **Authentication - Login**, enter your username and password.
* If prompted, enter your **OTP**.
* Look for your API key in the output pane:

```json
"auth_data": {
    "auth_token": "47A1157A-7AAC-4660-XXXX-34858F3A001C"
},
```

### Get-DCAPIToken

Run one of the following lines, depending on whether you have 2FA enabled on your account:

```powershell
Get-DCAPIToken -HostName DCSERVER -Credential 'DOMAIN\User'
```

```powershell
Get-DCAPIToken -HostName DCSERVER -Credential 'DOMAIN\User' -OTP 123456
```

* You will be prompted for your password.
* If your Desktop Central authentication is local only, omit the DOMAIN and use just the USERNAME.
* If your Desktop Central server is enabled for ```HTTPS```, then only the server name is required.
* If you want to use ```HTTP``` only, then prefix the server name with ```http://```.

You will receive a return object like below:

```powershell
auth_data                                          two_factor_data               user_data
---------                                          ---------------               ---------
@{auth_token=47A1157A-7AAC-4660-XXXX-34858F3A001C} @{is_TwoFactor_Enabled=False} @{auth_type=Local Authentication; user_id=1; u...
```

## Getting Started

Once you have your API key, the simplest method is to declare a parameter block at the top of the script with your server name and API key, then use that parameter block for all cmdlet calls.

```powershell
@DCParameters = @{
    AuthToken = '47A1157A-7AAC-4660-XXXX-34858F3A001C'
    HostName  = 'deskcent01.contoso.com'
}
Get-DCAPIComputer @DCParameters
```
