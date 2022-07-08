#Requires -RunAsAdministrator

Start-Transcript -Path "$PSScriptRoot\setup-install.log"

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
    $configJSON = (Get-Content -Raw -Path "$PSScriptRoot\config.json" | ConvertFrom-Json)
}
else {
    Write-Host `n"Config.json not found!" -ForegroundColor Red
    Stop-Transcript
    Exit
}

# save task user to windows credential manager
if (!(Get-StoredCredential -Target "---UpdateAzADAppProxyCert--TaskUser")) {
    Write-Host "No entry for ---UpdateAzADAppProxyCert--TaskUser found in Credential Manager" -ForegroundColor Red
    $currentUserCred = Get-Credential -UserName $currentUser -Message 'Please enter credentials for the current user: '
    New-StoredCredential -Target "---UpdateAzADAppProxyCert--TaskUser" -Credentials $currentUserCred
}
else {
    Write-Host "Credentials for ---UpdateAzADAppProxyCert--TaskUser already in Credential manager." -ForegroundColor Yellow
}

$currentUserCred = Get-StoredCredential -Target "---UpdateAzADAppProxyCert--TaskUser"
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($currentUserCred.Password);
$plainbstr = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr);

foreach ($certificate in $configJSON) {
    # save azure credentials to windows credential manager
    if (!(Get-StoredCredential -Target $certificate.azureUserCredMgrTarget)) {
        Write-Host "No entry for $($certificate.azureUserCredMgrTarget) found in Credential Manager" -ForegroundColor Red
        Write-Host 'Please enter credentials for an azure user with application administrator role.' -ForegroundColor Yellow
        New-StoredCredential -Target $certificate.azureUserCredMgrTarget -Credentials $(Get-Credential)
    }
    else {
        Write-Host "Credentials for $($certificate.azureUserCredMgrTarget) already in Credential manager." -ForegroundColor Yellow
    }

    # save pfx password to windows credential manager
    if (!(Get-StoredCredential -Target $certificate.azurePFXCredMgrTarget)) {
        Write-Host "No entry for $($certificate.azurePFXCredMgrTarget) found in Credential Manager" -ForegroundColor Red
        Write-Host "Please enter pfx password for the $($certificate.primaryUrl) pfx file: " -ForegroundColor Yellow
        New-StoredCredential -Target $certificate.azurePFXCredMgrTarget -UserName $certificate.primaryUrl -Password $(Read-Host)
    }
    else {
        Write-Host "Credentials for $($certificate.azurePFXCredMgrTarget) already in Credential manager." -ForegroundColor Yellow
    }

    # add scheduled task witout schedule
    if (Get-ScheduledTask -TaskName $certificate.taskName -ErrorAction SilentlyContinue) {
        Write-Host "Update task $($certificate.taskName) is already created." -ForegroundColor Yellow
    }
    else {
        Write-Host 'Creating scheduled task... ' -ForegroundColor Yellow
       
        $taskName = $certificate.taskName
        $tenantID = $certificate.tenantID
        $azureCredTarget = $certificate.credentialManagerEntry
        $appRegistrationObjectID = $certificate.appRegistrationObjectID

        $argument = "-Command `"& '$PSScriptRoot\Update-AzureADAppProxyCertificate.ps1' -taskName '$taskName' -tenantID '$tenantID' -azureCredTarget $azureCredTarget -appRegistrationObjectID '$appRegistrationObjectID'`""
        $action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $argument -WorkingDirectory $PSScriptRoot
        $trigger = New-ScheduledTaskTrigger -Once -At '01/01/2022 01:00:00 AM'
        $principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Password -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet
        $task = New-ScheduledTask -Description 'Task is triggerd manualy by "Certify the Web" and updates the azure app proxy certificate for custom domain.' -Action $action -Principal $principal -Trigger $trigger -Settings $settings
        
        Register-ScheduledTask -TaskName $taskName -InputObject $task -User $currentUser -Password $plainbstr
    }
}

Stop-Transcript