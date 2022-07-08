[CmdletBinding()]
param (
    [Parameter()]$result,
    [Parameter()][string]$primaryUrl
)

Start-Transcript -Path "$PSScriptRoot\Start-ScheduledTask_$primaryUrl.log"

$currentUser = whoami
Write-Host "Running Start-ScheduledTask.ps1 as $currentUser"

$pfxFilePath = $result.ManagedItem.CertificatePath

$configJSON = (Get-Content -Raw -Path "$PSScriptRoot\config.json" | ConvertFrom-Json)
$configJSON | ForEach-Object {if($_.primaryUrl -eq $primaryUrl){$_.certificatePath=$pfxFilePath}}
$configJSON | ConvertTo-Json -Depth 32 | Set-Content "$PSScriptRoot\config.json"

$configJSON = (Get-Content -Raw -Path "$PSScriptRoot\config.json" | ConvertFrom-Json)
$configEntry = $configJSON | Where-Object primaryUrl -eq $primaryUrl
$taskName = $configEntry.taskName

Start-ScheduledTask -TaskName $taskName -Verbose

Stop-Transcript