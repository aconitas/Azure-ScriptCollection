# Description
Working with Azure PowerShell could sometimes become annoying because of not available VM SKUs.
Either the subscription is not allowed to deploy a specific vm or there are now ressources at the choosen region.

This script gives a list of possible VM SKUs for your subscription, specified region and planned sku

# Parameter
| Parameter | Default Value | Description |
|---|---|---|
| FilterAzureRegion | n/a | Azure Region|
| FilterVMSKU| n/a | Azure VM SKU or empty for all |

# Usage Example
```powershell

PS C:\Users\user.name\.git\Azure-ScriptCollection\Get-AvailableVMSKUs> .\Get-AvailableVMSKUs.ps1

cmdlet Get-AvailableVMSKUs.ps1 at command pipeline position 1
Supply values for the following parameters:
TenantID: 00000000-0000-0000-0000-000000000000
FilterAzureRegion: westeurope
FilterVMSKU: Standard_D4

Account               SubscriptionName          TenantId                             Environment
-------               ----------------          --------                             -----------
user@domain.tld       Subscription 1            00000000-0000-0000-0000-000000000000 AzureCloud



Name                 Location   Applies to SubscriptionID            Subscription Restriction                   Zone Re
                                                                                                                stricti
                                                                                                                on
----                 --------   -------------------------            ------------------------                   -------
Standard_D4          westeurope 00000000-0000-0000-0000-000000000000 NotAvailableInRegion                       NotA...
Standard_D4_v2       westeurope 00000000-0000-0000-0000-000000000000 NotAvailableInRegion                       NotA...
Standard_D4_v2_Promo westeurope 00000000-0000-0000-0000-000000000000 NotAvailableInRegion                       NotA...
Standard_D4_v3       westeurope 00000000-0000-0000-0000-000000000000 NotAvailableInRegion                       NotA...
Standard_D4_v4       westeurope 00000000-0000-0000-0000-000000000000 NotAvailableInRegion                       NotA...
Standard_D4_v5       westeurope 00000000-0000-0000-0000-000000000000 NotAvailableInRegion                       NotA...
Standard_D48_v3      westeurope 00000000-0000-0000-0000-000000000000 NotAvailableInRegion                       NotA...
Standard_D48_v4      westeurope 00000000-0000-0000-0000-000000000000 NotAvailableInRegion                       NotA...
Standard_D48_v5      westeurope 00000000-0000-0000-0000-000000000000 NotAvailableInRegion                       NotA...
Standard_D48a_v4     westeurope 00000000-0000-0000-0000-000000000000 NotAvailableInRegion                       NotA...
Standard_D48ads_v5   westeurope 00000000-0000-0000-0000-000000000000 Available - No region restrictions applied Avai...
...
...
...
```