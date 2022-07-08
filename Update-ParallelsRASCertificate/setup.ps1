[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$certName,
    [Parameter(Mandatory)][string]$crMgrTarget
)

Start-Transcript -Path "$PSScriptRoot\setup.log"

$currentUser = whoami
Write-Host "Running setup.ps1 as $currentUser"

$requiredPSModules = 'CredentialManager'

foreach ($psModule in $requiredPSModules) {
    if (Get-Module -Name $psModule) {
        Write-Host `n"Required PowerShell Module $psModule is installed." -ForegroundColor Yellow
        Import-Module -Name $psModule
    }
    else {
        Write-Host `n"Required PowerShell Module $psModule is not installed. Installing..." -ForegroundColor Yellow
        Install-Module -Name $psModule
        Import-Module -Name $psModule
    }
}

# save service account credentials to windows credential manager
if (!(Get-StoredCredential -Target $crMgrTarget)) {
    Write-Host "No entry for $crMgrTarget found in Credential Manager" -ForegroundColor Red
    Write-Host 'Please enter credentials for an Service Account with permissions at RAS Console.' -ForegroundColor Yellow
    New-StoredCredential -Target $crMgrTarget -Credentials $(Get-Credential)
}
else {
    Write-Host "Credentials for $crMgrTarget already in Credential manager." -ForegroundColor Yellow
}

$taskName = "---UpdateParallelsRASCertificate-$certName"
$saRasUser = (Get-StoredCredential -Target $crMgrTarget).UserName
$saRasPw = (Get-StoredCredential -Target $crMgrTarget).Password

# add scheduled task witout schedule
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Host "Update task $taskName is already created." -ForegroundColor Yellow
}
else {
    Write-Host 'Creating scheduled task... ' -ForegroundColor Yellow
    $action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $trigger = New-ScheduledTaskTrigger -Once -At '01/01/2022 01:00:00 AM'
    $settings = New-ScheduledTaskSettingsSet
    Register-ScheduledTask  -TaskName $taskName `
                            -TaskPath "\aconitas"
                            -Action $action `
                            -Trigger $trigger `
                            -User $saRasUser `
                            -Password $saRasPw `
                            -Settings $settings `
                            -Description 'Task is triggerd manualy by "Certify the Web" and updates the Parallels RAS Certificate.'
}

Stop-Transcript