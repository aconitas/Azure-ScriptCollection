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
    $configJSON = (Get-Content -Raw -Path "$PSScriptRoot\config.json" | ConvertFrom-Json)
}
else {
    Write-Host `n"Config.json not found!" -ForegroundColor Red
    Stop-Transcript
    Exit
}

if (!(Get-StoredCredential -Target $configJSON.importCertificatePassword)) {
    Write-Host "No entry for $($configJSON.importCertificatePassword) found in Credential Manager!" -ForegroundColor Red
}
else {
    Write-Host "Credentials for $($configJSON.importCertificatePassword) already in Credential manager." -ForegroundColor Yellow

    # Convert SecureString object to plain text, because certutil do not support SecureString objects
    $secureCertificatePassword = (Get-StoredCredential -Target test).Password
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureCertificatePassword)
    $plainCertificatePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

}

Stop-Service "Pleasant Password Server"
Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -Like "CN=$($configJSON.certificateCN)" } | Remove-Item
certutil –f –p $plainCertificatePassword –importpfx $($configJSON.importCertificatePath)
$certThumb = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -match "$($configJSON.certificateCN)"}).Thumbprint 
Set-ItemProperty "HKLM:\Software\Pleasant Solutions\PasswordManager" -Name CertificateName -Value "$($configJSON.certificateCN)"
Set-ItemProperty "HKLM:\Software\Pleasant Solutions\PasswordManager" -Name ThumbPrint -Value $certThumb
Restart-Service "Pleasant Password Server"
