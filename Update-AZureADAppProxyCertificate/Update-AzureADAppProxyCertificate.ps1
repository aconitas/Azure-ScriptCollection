# First you need to add Credentials to Store: 
# New-StoredCredential -Target 'User_AppProxyCertificateChange' -Credentials $(Get-Credential)

[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$TenantID,
    [Parameter(Mandatory)][string]$AppRegistrationObjectID,
    [Parameter(Mandatory)][string]$PFXFilePath,
    [Parameter(Mandatory)][securestring]$PFXFilePassword
)

#Requires -Version 5.1
#Requires -Modules AzureAD
#Requires -Modules CredentialManager

If ((Test-Path -Path $PFXFilePath) -eq $False) {
    Write-Host "The pfx file does not exist." -ForegroundColor Red
    Write-Host " "

    Exit
}
else {Write-Host "Pass PFX Path Test"}

if (!(Get-StoredCredential -Target 'User_AppProxyCertificateChange')) {
    Write-Host "No credentials for User_AppProxyCertificateChange" -ForegroundColor Red
}
else {Write-Host "Pass CredentialManager Test"}

$Credential = Get-StoredCredential -Target 'User_AppProxyCertificateChange'

Connect-AzureAD -TenantID $TenantID -Credential $Credential
Set-AzureADApplicationProxyApplicationCustomDomainCertificate -ObjectId $AppRegistrationObjectID -PFXFilePath $PFXFilePath -Password $PFXFilePassword -Verbose
Disconnect-AzureAD