[CmdletBinding()]
param (
	[Parameter(Mandatory)][string]$primaryUrl
)

Start-Transcript -Path "$PSScriptRoot\Update-AzureADAppProxyCertificate_$primaryUrl.log"

$configJSON = (Get-Content -Raw -Path "$PSScriptRoot\config.json" | ConvertFrom-Json)
$configEntry = $configJSON | Where-Object primaryUrl -eq $primaryUrl

$pfxFilePath = $configEntry.certificatePath

$credential = Get-StoredCredential -Target $configEntry.azureUserCredMgrTarget
$pfxFilePassword = (Get-StoredCredential -Target $configEntry.taskName).Password

Write-Host "Connect to Azure... " -ForegroundColor Yellow
Connect-AzureAD -TenantID $configEntry.tenantID -Credential $credential -Verbose

Write-Host "Upload Certificate to Azure..." -ForegroundColor Yellow
Set-AzureADApplicationProxyApplicationCustomDomainCertificate -ObjectId $configEntry.appRegistrationObjectID -PFXFilePath $pfxFilePath -Password $pfxFilePassword -Verbose

Write-Host "Disconnect from Azure... " -ForegroundColor Yellow
Disconnect-AzureAD -Verbose

Stop-Transcript