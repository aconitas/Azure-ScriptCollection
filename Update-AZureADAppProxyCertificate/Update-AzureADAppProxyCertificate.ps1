[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$taskName,
    [Parameter(Mandatory)][string]$tenantID,
    [Parameter(Mandatory)][string]$azureCredTarget,
    [Parameter(Mandatory)][string]$appRegistrationObjectID,
    [Parameter(Mandatory)][string]$pfxFilePath
)

Start-Transcript -Path "$PSScriptRoot\Update-AzureADAppProxyCertificate.log"

$credential = Get-StoredCredential -Target $azureCredTarget
$pfxFilePassword = (Get-StoredCredential -Target $taskName).Password

Write-Host "Connect to Azure... " -ForegroundColor Yellow
Connect-AzureAD -TenantID $tenantID -Credential $credential -Verbose

Write-Host "Upload Certificate to Azure..." -ForegroundColor Yellow
Set-AzureADApplicationProxyApplicationCustomDomainCertificate -ObjectId $appRegistrationObjectID -PFXFilePath $pfxFilePath -Password $pfxFilePassword -Verbose

Write-Host "Disconnect from Azure... " -ForegroundColor Yellow
Disconnect-AzureAD -Verbose

Stop-Transcript