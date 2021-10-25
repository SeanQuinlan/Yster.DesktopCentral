$Current_TimeZone = (Get-WmiObject -ClassName Win32_TimeZone).StandardName
$TimeZone_Info = [System.TimeZoneInfo]::FindSystemTimeZoneById($Current_TimeZone)

$Patch_Status_Mapping = @{
    'Installed' = 201
    'Missing'   = 202
    'Failed'    = 206
}

$Approval_Status_Mapping = @{
    'NotApproved' = 0
    'Approved'    = 211
    'Declined'    = 212
}

$Severity_Mapping = @{
    'Unrated'   = 0
    'Low'       = 1
    'Moderate'  = 2
    'Important' = 3
    'Critical'  = 4
}

$Health_Mapping = @{
    'Unknown'          = 0
    'Healthy'          = 1
    'Vulnerable'       = 2
    'HighlyVulnerable' = 3
}

$LiveStatus_Mapping = @{
    'Live'    = 1
    'Down'    = 2
    'Unknown' = 3
}

$Group_Types_Mapping = @{
    'Computer' = 1
    'User'     = 2
}

$Group_Categories_Mapping = @{
    'Static'       = 1
    'Dynamic'      = 2
    'StaticUnique' = 5
}

$OSPlatform_Mapping = @{
    'Windows' = 1
    'Mac'     = 2
    'Linux'   = 3
}

# For APD collections.
$Collection_Status_Mapping = @{
    'Active'    = 4
    'Suspended' = 5
}

# From: https://stackoverflow.com/questions/11696944/powershell-v3-invoke-webrequest-https-error/55246366
$TrustAllCertsPolicy = @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
Add-Type -TypeDefinition $TrustAllCertsPolicy
