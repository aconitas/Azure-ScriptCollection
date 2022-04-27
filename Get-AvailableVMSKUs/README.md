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
.\Get-AvailableVMSKUs.ps1 -FilterAzureRegion "" -FilterVMSKU ""
```