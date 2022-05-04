[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$taskName,
    [Parameter(Mandatory)][string]$tenantID,
    [Parameter(Mandatory)][string]$appRegistrationObjectID
)

Start-Transcript -Path "$PSScriptRoot\Setup-Script.log"

$configJSON = @()
$configJSONSetting = "" | Select TaskName,TenantID,AppRegistrationObjectID
$configJSONSetting.TaskName = $taskName
$configJSONSetting.TenantID = $tenantID
$configJSONSetting.AppRegistrationObjectID = $appRegistrationObjectID
$configJSON += $configJSONSetting
$configJSON | ConvertTo-Json | Out-File config.json

$requiredPSModules = 'AzureAD', 'CredentialManager'
$currentUser = whoami

foreach ($psModule in $requiredPSModules) {
    if (Get-Module -Name $psModule) {
        Write-Host "Required PowerShell Module $psModule is installed." -ForegroundColor Yellow
        Import-Module -Name $psModule
    }
    else {
        Write-Host "Required PowerShell Module $psModule is not installed. Installing..." -ForegroundColor Yellow
        Install-Module -Name $psModule -Verbose
        Import-Module -Name $psModule
    }
}

if (!(Get-StoredCredential -Target 'Azure_ApplicationAdministrator')) {
    Write-Host 'No credentials for Azure_ApplicationAdministrator in credential manager found!' -ForegroundColor Red
    Write-Host 'Please enter credentials for an azure user with application administrator role ...' -ForegroundColor Red
    New-StoredCredential -Target 'Azure_ApplicationAdministrator' -Credentials $(Get-Credential)
}
else {
    Write-Host 'Credentials for Azure_ApplicationAdministrator found in credential manager.' -ForegroundColor Green
}

if (!(Get-StoredCredential -Target $taskName)) {
    Write-Host "No password for the PFX File called $taskName in credential manager found!" -ForegroundColor Red
    Write-Host "Please enter the password for PFXFile:" -ForegroundColor Red
    New-StoredCredential -Target $taskName -UserName $taskName -Password $(Read-Host)
}
else {
    Write-Host "Credentials for PFX File for Task $taskName found in credential manager." -ForegroundColor Green
}

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Host 'Update task is already created.' -ForegroundColor Yellow
}
else {
    Write-Host 'Creating scheduled task... ' -ForegroundColor Yellow
    $action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $trigger = New-ScheduledTaskTrigger -Once -At '01/01/2022 01:00:00 AM'
    $principal = New-ScheduledTaskPrincipal -UserId $currentUser -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet
    $task = New-ScheduledTask -Description 'Task is triggerd manualy by "Certify the Web" and updates the azure app proxy certificate for custom domain.' -Action $action -Principal $principal -Trigger $trigger -Settings $settings
    Register-ScheduledTask -TaskName $taskName -InputObject $task
}

Stop-Transcript