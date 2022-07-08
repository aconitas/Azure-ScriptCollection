$RASUser="ras-powershell@aconitas-demo.de"
$RASPwd = ConvertTo-SecureString 'sIaec1!aJtama$_mHCv9bk' -AsPlainText -Force
$d=Get-Date -format "yyyyMMdd"
$CertPath= "C:\aconitas\Certificates"
$CertPathArchiv= "C:\aconitas\Certificates\archiv"
$CertName="ras.aconitas-demo.de"
$CertificatesPem=Get-ChildItem -Path $CertPath -Force | Where-Object {$_.Name -CLike "*.pem"}
$CertificatesKey=Get-ChildItem -Path $CertPath -Force | Where-Object {$_.Name -CLike "*.key"}
if (($CertificatesKey.Name -ne $null) -and ($CertificatesPem.Name -ne $null)) 
{ 
write-host ("Files found: " + $CertificatesPem + "; " + $CertificatesKey)
Import-Module RASAdmin
New-RASSession -Username $RASUser -Password $RASPwd
$OldCert=Get-RASCertificate
if ($OldCert -ne $null) 
{
$OldCert | ForEach-Object -Process {Remove-RASCertificate $_.Name}
}
$NewCert=New-RASCertificate -Name $CertName -CertificateFile $CertPath\$CertificatesPem -PrivateKeyFile $CertPath\$CertificatesKey
if ($NewCert -ne $null) 
{
$Gateways=Get-RASGW
if ($Gateways -ne $null) 
{
$Gateways | ForEach-Object -Process {Set-RASGW -Id $_.Id -CertificateId $NewCert[0].Id}
}
}
Invoke-RASApply
Remove-RASSession
Copy-Item -Path $CertPath\$CertificatesPem -Destination $CertPathArchiv\$d$CertificatesPem -Force
Copy-Item -Path $CertPath\$CertificatesKey -Destination $CertPathArchiv\$d$CertificatesKey -Force
Remove-Item -Path $CertPath\$CertificatesPem
Remove-Item -Path $CertPath\$CertificatesKey
} 
else {write-host("Files were not found")}
