Start-Transcript -Path "$PSScriptRoot\setup.log"

$currentUser = whoami
Write-Host "Running setup.ps1 as $currentUser"

$requiredPSModules = 'AzureAD', 'CredentialManager'

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

############################

foreach ($certificate in $configJSON) {
    # save azure credentials to windows credential manager
    if (!(Get-StoredCredential -Target $certificate.azureUserCredMgrTarget)) {
        Write-Host "No entry for ${certificate.azureUserCredMgrTarget} found in Credential Manager" -ForegroundColor Red
        Write-Host 'Please enter credentials for an azure user with application administrator role.' -ForegroundColor Yellow
        New-StoredCredential -Target $certificate.azureUserCredMgrTarget -Credentials $(Get-Credential)
    }
    else {
        Write-Host "Credentials for ${certificate.azureUserCredMgrTarget} already in Credential manager." -ForegroundColor Yellow
    }

    # save pfx password to windows credential manager
    if (!(Get-StoredCredential -Target $certificate.azurePFXCredMgrTarget)) {
        Write-Host "No entry for ${certificate.azurePFXCredMgrTarget} found in Credential Manager" -ForegroundColor Red
        Write-Host 'Please enter pfx password for the pfx file: ' -ForegroundColor Yellow
        New-StoredCredential -Target $certificate.primaryUrl -UserName $certificate.primaryUrl -Password $(Read-Host)
    }
    else {
        Write-Host "Credentials for ${certificate.azurePFXCredMgrTarget} already in Credential manager." -ForegroundColor Yellow
    }

    # add scheduled task witout schedule
    if (Get-ScheduledTask -TaskName $certificate.taskName -ErrorAction SilentlyContinue) {
        Write-Host "Update task ${certificate.taskName} is already created." -ForegroundColor Yellow
    }
    else {
        Write-Host 'Creating scheduled task... ' -ForegroundColor Yellow
        $action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        $trigger = New-ScheduledTaskTrigger -Once -At '01/01/2022 01:00:00 AM'
        $principal = New-ScheduledTaskPrincipal -UserId $currentUser -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet
        $task = New-ScheduledTask -Description 'Task is triggerd manualy by "Certify the Web" and updates the azure app proxy certificate for custom domain.' -Action $action -Principal $principal -Trigger $trigger -Settings $settings
        Register-ScheduledTask -TaskName $certificate.taskName -InputObject $task
    }
}

Stop-Transcript