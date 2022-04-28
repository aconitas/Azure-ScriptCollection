# Description
Script is used to Update the Azure AD App Proxy Certificate. After certificate request trough Certify the Web.

Adding this to CTW Tasks, doesn't work now because scripts are always run by the system account.

# Add Credentials to Windows Credential Manager
```powershell
New-StoredCredential -Target 'User_AppProxyCertificateChange' -Credentials $(Get-Credential)
```

# Parameters

# Usage Example
```powershell
.\Update-AzureADAppProxyCertificate.ps1 -TenantID "00000000-0000-0000-0000-000000000000" -AppRegistrationObjectID "10000000-1000-1000-1000-100000000000" -PFXFilePath "C:\Temp\certificate.pfx"
```