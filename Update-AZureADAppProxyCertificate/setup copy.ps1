Start-Transcript -Path "$PSScriptRoot\setup.log"

# Include required files
.\functions.ps1

$currentUser = whoami
Write-Host "Running setup.ps1 as $currentUser"

$requiredPSModules = 'AzureAD', 'CredentialManager'

foreach ($psModule in $requiredPSModules) {
    if (Get-Module -Name $psModule) {
        Write-Host "Required PowerShell Module $psModule is installed." -ForegroundColor Yellow
        Import-Module -Name $psModule
    }
    else {
        Write-Host "Required PowerShell Module $psModule is not installed. Installing..." -ForegroundColor Yellow
        Install-Module -Name $psModule
        Import-Module -Name $psModule
    }
}

if (Test-Path -Path "$PSScriptRoot\config.json" -PathType Leaf) {
    Write-Host "Found config.json ..." -ForegroundColor Yellow
    Write-Host "Import config.json ..." -ForegroundColor Yellow
    $configJSON = Get-Content -Raw -Path "$PSScriptRoot\config.json" | ConvertFrom-Json
}
else {
    Write-Host "Config.json not found!" -ForegroundColor Red
    Exit

    # $configJSON = @()
    # $configJSONSetting = "" | Select-Object Certificates
    # $configJSONSetting.Certificates[0]
    # $configJSON += $configJSONSetting
    # $configJSON | ConvertTo-Json | Out-File config.json
}

Stop-Transcript

function Show-Menu {
    param ([string]$Title = 'Setup Azure AD App Proxy Cert Update')
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Add"
    Write-Host "2: Update"
    Write-Host "3: Remove"
    Write-Host "Q: Press 'Q' to quit."
}

function AddScheduledTask ($taskName)
{
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
}

function AddPFXPassword ($credentialManagerTarget, $certificateUrl)
{
    if (!(Get-StoredCredential -Target $credentialManagerTarget)) {
        Write-Host "No entry for $credentialManagerTarget found in Credential Manager" -ForegroundColor Red
        Write-Host 'Please enter credentials for an azure user with application administrator role.' -ForegroundColor Yellow
        New-StoredCredential -Target $credentialManagerTarget -UserName $certificateUrl -Password $(Read-Host)
    }
    else {
        Write-Host "Credentials for $credentialManagerTarget already in Credential manager." -ForegroundColor Yellow

        $update = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes'
        $noupdate = New-Object System.Management.Automation.Host.ChoiceDescription '&No'
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($update, $noupdate)

        $title = 'Update Credentials?'
        $message = 'Would you like to update the credentials?'
        $updateCred = $host.ui.PromptForChoice($title, $message, $options, 0)

        switch ($updateCred) {
            0 {
                Remove-StoredCredential -Target $credentialManagerTarget
                New-StoredCredential -Target $credentialManagerTarget -UserName $certificateUrl -Password $(Read-Host)
            }
            1 { Write-Host "No change." -ForegroundColor Yellow }
        }
    }
}

function AddAzureCred ($credentialManagerTarget)
{
    if (!(Get-StoredCredential -Target $credentialManagerTarget)) {
        Write-Host "No entry for $credentialManagerTarget found in Credential Manager" -ForegroundColor Red
        Write-Host 'Please enter credentials for an azure user with application administrator role.' -ForegroundColor Yellow
        New-StoredCredential -Target $credentialManagerTarget -Credentials $(Get-Credential)
    }
    else {
        Write-Host "Credentials for $credentialManagerTarget already in Credential manager." -ForegroundColor Yellow

        $update = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes'
        $noupdate = New-Object System.Management.Automation.Host.ChoiceDescription '&No'
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($update, $noupdate)

        $title = 'Update Credentials?'
        $message = 'Would you like to update the credentials?'
        $updateCred = $host.ui.PromptForChoice($title, $message, $options, 0)

        switch ($updateCred) {
            0 {
                Remove-StoredCredential -Target $credentialManagerTarget
                New-StoredCredential -Target $credentialManagerTarget -Credentials $(Get-Credential)
            }
            1 { Write-Host "No change." -ForegroundColor Yellow }
        }
    }
}

function AddConfigEntry($certificateName, $taskName, $tenantID, $appRegistrationObjectID)
{
    $configJSON = (Get-Content -Raw config.json) -replace "//\s+.*","" | ConvertFrom-Json
    
    $configJSON.Certificates[0] | ConvertTo-Json > ".\temp_config.json"
    $newCertificate = (Get-Content -Raw ".\temp_config.json") | ConvertFrom-Json
    
    $newCertificate.certificateName = $certificateName
    $newCertificate.taskName = $taskName
    $newCertificate.tenantID = $tenantID
    $newCertificate.appRegistrationObjectID = $appRegistrationObjectID

    $configJSON.Certificates += $newCertificate

    $configJSON | ConvertTo-Json | Out-File -Encoding utf8 .\config.json

    Remove-Item .\temp_config.json
}