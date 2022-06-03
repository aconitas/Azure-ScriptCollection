[CmdletBinding()]
param (
    [Parameter()]$result,
    [Parameter()][string]$primaryUrl
)

Start-Transcript -Path "$PSScriptRoot\Start-ScheduledTask.log"

$currentUser = whoami
Write-Host "Running setup.ps1 as $currentUser"

$configJSON = (Get-Content -Raw -Path "$PSScriptRoot\config.json" | ConvertFrom-Json).Certificates
$configEntry = $configJSON | Where-Object primaryUrl -eq $primaryUrl

$taskName = $configEntry.taskName
$tenantID = $configEntry.tenantID
$azureCredTarget = $configEntry.credentialManagerEntry
$appRegistrationObjectID = $configEntry.appRegistrationObjectID

$pfxFilePath = $result.ManagedItem.CertificatePath

$taskUserCred = Get-StoredCredential -Target "---UpdateAzADAppProxyCert--TaskUser"
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($taskUserCred.Password);
$plainbstr = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr);

$argument = "-Command `"& '$PSScriptRoot\Update-AzureADAppProxyCertificate.ps1' -taskName '$taskName' -tenantID '$tenantID' -azureCredTarget $azureCredTarget -appRegistrationObjectID '$appRegistrationObjectID' -pfxFilePath '$pfxFilePath'`""
$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $argument -WorkingDirectory $PSScriptRoot
Set-ScheduledTask -TaskName $taskName -Action $action -User $taskUserCred.UserName -Password $plainbstr

# Start-ScheduledTask -TaskName $taskName -Verbose

Stop-Transcript