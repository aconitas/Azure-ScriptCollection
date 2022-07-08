[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$certPath,
    [Parameter(Mandatory)][string]$certName,
    [Parameter(Mandatory)][string]$crMgrTarget
)

Start-Transcript -Path "$PSScriptRoot\CertificateRollScript.log"

$requiredPSModules = 'RASAdmin', 'CredentialManager'
foreach ($psModule in $requiredPSModules) {
    if (Get-Module -Name $psModule) {
        Write-Host `n"### Required PowerShell Module $psModule is installed." -ForegroundColor Yellow
        Import-Module -Name $psModule
    }
    else {
        Write-Host `n"### Required PowerShell Module $psModule is not installed. Installing..." -ForegroundColor Yellow
        Install-Module -Name $psModule
        Import-Module -Name $psModule
    }
}

$saUpnRas = (Get-StoredCredential -Target $crMgrTarget).UserName
$saPwRas = ConvertTo-SecureString (Get-StoredCredential -Target $crMgrTarget).Password -AsPlainText -Force

$currentDate = Get-Date -format "yyyyMMdd"

$certPEM = Get-ChildItem -Path $certPath -Force | Where-Object {$_.Name -CLike "*.pem"}
$certKEY = Get-ChildItem -Path $certPath -Force | Where-Object {$_.Name -CLike "*.key"}

if (($null -ne $certKEY.Name) -and ($null -ne $certPEM.Name)) 
{ 
    Write-Host "### Found the following pem-file: $certPEM" 
    Write-Host "### Found the following key-file: $certKEY"

    New-RASSession -Username $saUpnRas -Password $saPwRas
    $oldCert = Get-RASCertificate
    
    if ($null -ne $oldCert) 
    {
        $oldCert | ForEach-Object -Process {Remove-RASCertificate $_.Name}
    }
    
    $newCert  = New-RASCertificate -Name $certName -CertificateFile $certPath\$certPEM -PrivateKeyFile $certPath\$certKEY
    
    if ($null -ne $newCert) 
    {
        $rasGateway = Get-RASGW

        if ($null -ne $rasGateway) 
        {
            $rasGateway | ForEach-Object -Process {Set-RASGW -Id $_.Id -CertificateId $newCert[0].Id}
        }
    }

    Invoke-RASApply
    Remove-RASSession
    
    Write-Host "### Moving old files to archiv folder ..."
    Move-Item -Path $certPath\$certPEM -Destination $certPath\archiv\$currentDate$certPEM -Force
    Move-Item -Path $certPath\$certKEY -Destination $certPath\archiv\$currentDate$certKEY -Force
} 
else {
    Write-Host "### ERROR: No certificate files found in: $certPath"
}

Stop-Transcript