$Current_TimeZone = (Get-WmiObject -ClassName Win32_TimeZone).StandardName
$TimeZone_Info = [System.TimeZoneInfo]::FindSystemTimeZoneById($Current_TimeZone)

$Patch_Status_Mapping = @{
    'Installed' = 201
    'Missing'   = 202
    'Failed'    = 206
}

$Approval_Status_Mapping = @{
    'Approved'    = 211
    'NotApproved' = 212
}

$Severity_Mapping = @{
    'Unrated'   = 0
    'Low'       = 1
    'Moderate'  = 2
    'Important' = 3
    'Critical'  = 4
}
