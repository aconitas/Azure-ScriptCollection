[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$certPath,
    [Parameter(Mandatory)][string]$certName,
    [Parameter(Mandatory)][string]$crMgrTarget
)


Start-Transcript -Path "$PSScriptRoot\Start-ScheduledTask.log"

$taskName = "---UpdateParallelsRASCertificate-$certName"

$argument = "-Command `"& '$PSScriptRoot\Update-ParallelsRASCertificate.ps1' certPath '$certPath' -certName '$certName' -crMgrTarget $crMgrTarget`""
$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $argument -WorkingDirectory $PSScriptRoot
Set-ScheduledTask -TaskName $taskName -Action $action -Verbose

Start-ScheduledTask -TaskName $taskName -Verbose

Stop-Transcript