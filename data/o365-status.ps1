param (
  [string]$Service,
  [string]$TenantId,
  [string]$IncludeAdvisoryString = 'false'
)

if (!$Service) {
  Write-Error "Missing required argument `"Service`", at the 1st position"
  exit
}
if (!$TenantId) {
  Write-Error "Missing required argument `"TenantId`", at the 2nd position"
  exit
}
$IncludeAdvisory = $false
if ($IncludeAdvisoryString -eq 'true') { $IncludeAdvisory = $true }

$StatusMapping = @{
    ServiceOperational      = 99
    InformationUnavailable  = 8
    PIRPublished            = 7
    FalsePositive           = 6
    ServiceRestored         = 5
    Investigating           = 4
    ExtendedRecovery        = 3
    RestoringService        = 2
    ServiceDegradation      = 1
    ServiceInterruption     = 0
}

Function SecureStringToString($Value)
{
    [System.IntPtr] $Bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($value);
    try
    {
        [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($Bstr);
    }
    finally
    {
        [System.Runtime.InteropServices.Marshal]::FreeBSTR($Bstr);
    }
}
$Cred = Get-Credential -credential ${CREDENTIAL}
[string] $ClientId = $Cred.Username
[string] $ClientSecret = SecureStringToString $Cred.Password

# Construct Body for OAuth Token
$Body = @{
  client_id     = $ClientId
  scope         = "https://manage.office.com/.default"
  client_secret = $ClientSecret
  grant_type    = "client_credentials"
}

# Get OAuth 2.0 Token
$Token = try {
  $Response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $Body -ErrorAction Stop
  $Response.access_token
}
catch [System.Net.WebException] {
  Write-Warning "Exception was caught: $($_.Exception.Message)"
}

# Get status for services
$O365Status = try {
  $Response = Invoke-RestMethod -Method Get -Uri "https://manage.office.com/api/v1.0/$TenantId/ServiceComms/CurrentStatus" -ContentType "application/json" -Headers @{Authorization = "Bearer $Token"} -ErrorAction Stop
  $Response.value | Where-Object { $_.Id -eq $Service }
}
catch [System.Net.WebException] {
  Write-Warning "Exception was caught: $($_.Exception.Message)"
}

# Early return if everything is ok
if ($O365Status.status -eq "ServiceOperational") {
  Write-host 'Statistic: 99'
  write-host 'Message: '$O365Status.StatusDisplayname
  exit
}

# Get Office 365 Messages
$O365Messages = try {
  $Response = Invoke-RestMethod -Method Get -Uri "https://manage.office.com/api/v1.0/$TenantId/ServiceComms/Messages?`$filter=Workload eq '$Service'" -ContentType "application/json" -Headers @{Authorization = "Bearer $Token"} -ErrorAction Stop
  $Response.value 
}
catch [System.Net.WebException] {
  Write-Warning "Exception was caught: $($_.Exception.Message)"
}

if (!$IncludeAdvisory) {
  $O365Messages = $O365Messages | Where-Object { $_.Classification -ne "Advisory" }
}

$O365Messages = $O365Messages | Where-Object { $O365Status.IncidentIds -contains $_.Id }

$MessagesToDisplay = foreach ($Message in $O365Messages) {
  "&lt;p&gt;&lt;b&gt;[$($Message.Classification)]&lt;/b&gt; $($Message.Status) - ID: $($Message.Id) - $($Message.ImpactDescription)&lt;/p&gt;"
}

# Check if there are any valuable messages after a potential "Advisory" filter
if (@($O365Messages).length -lt 1) {
  Write-host 'Statistic: 99'
  write-host 'Message: Service Operational'
  exit
}

Write-Host 'Statistic: '$StatusMapping[$O365Status.Status]
write-host 'Message: '$MessagesToDisplay

exit
