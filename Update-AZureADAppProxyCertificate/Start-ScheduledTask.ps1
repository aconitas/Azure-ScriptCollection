[CmdletBinding()]
param (
    [Parameter()]$result
)

Start-Transcript -Path "$PSScriptRoot\Start-ScheduledTask.log"

$configJSONImport = Get-Content -Raw -Path "$PSScriptRoot\config.json" | ConvertFrom-Json
$taskName = $configJSONImport.TaskName
$tenantID = $configJSONImport.TenantID
$appRegistrationObjectID = $configJSONImport.AppRegistrationObjectID
$pfxFilePath = $result.ManagedItem.CertificatePath

$argument = "-Command `"& '$PSScriptRoot\Update-AzureADAppProxyCertificate.ps1' -taskName '$taskName' -tenantID '$tenantID' -appRegistrationObjectID '$appRegistrationObjectID' -pfxFilePath '$pfxFilePath'`""
$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $argument -WorkingDirectory $PSScriptRoot
Set-ScheduledTask -TaskName $taskName -Action $action -Verbose

Start-ScheduledTask -TaskName $taskName -Verbose

Stop-Transcript