# Description

# Parameter
There are only a few parameters for the Setup-Script.ps1 but I recommend to run the script without parameters an let it ask you all it needs.

| Parameter | Default Value | Description |
|---|---|---|
| TaskName | n/a | Display Name for Scheduled Task |
| TenantID | n/a | Microsoft Tenant ID, can be shown in Azure Portal |
| AppRegistrationObjectID | n/a | Object ID of the App Registration for your App. |

# Usage Example
```powershell
PS C:\Temp\ChangeAzureCertificate> .\Setup-Script.ps1
cmdlet Setup-Script.ps1 at command pipeline position 1
Supply values for the following parameters:
taskName: AzuerCertChange-Test
tenantID: 84dfafd5-910b-4de5-9f8b-408e215d19c7
appRegistrationObjectID: 8790b635-4816-40a1-9dee-5918859d45f7
Transcript started, output file is C:\aconitas\ChangeAzureCertificate\Setup-Script.log
Required PowerShell Module AzureAD is not installed. Installing...
```