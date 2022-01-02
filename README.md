# Yster.DesktopCentral

This is a PowerShell module to interact with ManageEngine's Desktop Central API.

Currently Desktop Central has 2 separate APIs:

* The old v1.3 version of the API - available at /api/1.3
* The newer DCAPI version - available at /dacpi

Only the older version of the API is [documented online](https://www.manageengine.com/products/desktop-central/api/index.html). The newer DCAPI endpoints have been pieced together via documentation sent by Manage Engine, examining the javascript files on the server and through some trial and error.

I have used different prefixes to separate the cmdlets between the API versions:

* All the older API functions use the prefix "DC".
* All newer API functions use "DCAPI".

## Getting Started

### Manually

* Download the zip of this repository via the Code button at the top right.
* Extract the zip file.
* Import the module:
```Import-Module .\Source\Yster.DesktopCentral.psd1```
