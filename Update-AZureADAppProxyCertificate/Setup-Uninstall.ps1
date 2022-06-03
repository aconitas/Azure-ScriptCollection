#Requires -RunAsAdministrator

Start-Transcript -Path "$PSScriptRoot\setup-uninstall.log"

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

if (Test-Path -Path "$PSScriptRoot\config.json" -PathType Leaf) {
    Write-Host `n"Found config.json ..." -ForegroundColor Yellow
    Write-Host  "Import config.json ..." -ForegroundColor Yellow
    $configJSON = (Get-Content -Raw -Path "$PSScriptRoot\config.json" | ConvertFrom-Json).Certificates
}
else {
    Write-Host `n"Config.json not found!" -ForegroundColor Red
    Stop-Transcript
    Exit
}

# remove task user from windows credential manager
if (!(Get-StoredCredential -Target "---UpdateAzADAppProxyCert--TaskUser")) {
    Write-Host "No entry for ---UpdateAzADAppProxyCert--TaskUser found in Credential Manager" -ForegroundColor Yellow
}
else {
    Write-Host "Credentials for ---UpdateAzADAppProxyCert--TaskUser found in Credential manager. Delete ..." -ForegroundColor Yellow
    Remove-StoredCredential -Target "---UpdateAzADAppProxyCert--TaskUser"
}

foreach ($certificate in $configJSON) {
    # remove azure credentials from windows credential manager
    if (!(Get-StoredCredential -Target $certificate.azureUserCredMgrTarget)) {
        Write-Host "No entry for $($certificate.azureUserCredMgrTarget) found in Credential Manager" -ForegroundColor Yellow
    }
    else {
        Write-Host "Credentials for $($certificate.azureUserCredMgrTarget) found in Credential manager. Delete ..." -ForegroundColor Yellow
        Remove-StoredCredential -Target $certificate.azureUserCredMgrTarget
    }

    # remove pfx password from windows credential manager
    if (!(Get-StoredCredential -Target $certificate.azurePFXCredMgrTarget)) {
        Write-Host "No entry for $($certificate.azurePFXCredMgrTarget) found in Credential Manager" -ForegroundColor Yellow
    }
    else {
        Write-Host "Credentials for $($certificate.azurePFXCredMgrTarget) already found Credential manager. Delete ..." -ForegroundColor Yellow
        Remove-StoredCredential -Target $certificate.azurePFXCredMgrTarget 
    }

    # remove scheduled task
    if (Get-ScheduledTask -TaskName $certificate.taskName -ErrorAction SilentlyContinue) {
        Write-Host "Found task $($certificate.taskName) at scheduler. Delte ..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $($certificate.taskName) -Confirm:$false
    }
    else {
        Write-Host 'No scheduled task found.' -ForegroundColor Yellow
    }
}

Stop-Transcript