# Description
The script creates a service principal called 'Parallels RAS' for the RAS AVD connection. 
Information source: https://kb.parallels.com/125236

The following roles will be set:
- 'User Access Administrator' at subscription level
- 'Contributor' on resource group level

Service Principal API permissions:
- Microsoft Graph / Application / User.Read.All
- Microsoft Graph / Application / Group.Read.All

The API permissions requires admin consent via Azure Portal because Azure PowerShell Module Az doesn't support it yet.

There is a second script to fully remove the created Service Principal from your tenant. Witout leaving some 'Uknown' entrys at the IAM.

# Parameter
| Parameter | Default Value | Description |
|---|---|---|
| TenantId | n/a |  |
| SubscriptionID | n/a |  |
| ResourceGroups | n/a | Multible groups can uses separated by comma. |


# Usage Example
Creation-Script:
```powershell

PS C:\Temp> .\Create-SPParallelsAVD.ps1 -TenantID 00000000-0000-0000-0000-000000000000 -SubscriptionID 00000000-0000-0000-0000-000000000000 -ResourceGroups 'test-rg','test2-rg'
```

Removal Script
```powershell

PS C:\Temp> .\Remove-SPParallelsAVD.ps1 -TenantID 00000000-0000-0000-0000-000000000000 -SubscriptionID 00000000-0000-0000-0000-000000000000
```
