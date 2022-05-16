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
    $configJSON = Get-Content -Raw -Path "$PSScriptRoot\config.json" | ConvertFrom-Json
}
else {
    Write-Host `n"Config.json not found!" -ForegroundColor Red
    Stop-Transcript
    Exit
}

###
###
Write-Host `n"Creating Tasks, based on config.json ..." -ForegroundColor Yellow
$certificateURL = Read-Host "Please provide primary URL of the certificate"

$azureUserCredMgrTarget = $configJSON.Certificates | Where-Object
$pfxPwCredMgrTarget = $configJSON.Certificates

# Azure Creds
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

# PFX Password


# Add Task

###
###
Stop-Transcript