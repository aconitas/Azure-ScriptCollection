# test 

[CmdletBinding()]
param (
    [Parameter(Mandatory)][ValidateNotNullorEmpty()][TypeName]$FilterAzureRegion,
    [Parameter(Mandatory)][ValidateNotNullorEmpty()][TypeName]$FilterVMSKU
)

#Requires -Modules Az

Connect-AzAccount

$SubscriptionID = (Get-AzContext).Subscription.Id

$FilterVMSKUs = Get-AzComputeResourceSku | Where-Object {$_.Locations.Contains($FilterAzureRegion) -and $_.ResourceType.Contains("virtualMachines") -and $_.Name.Contains($FilterVMSKU)}

$OutTable = @()

foreach ($SkuName in $FilterVMSKUs.Name)
{
    $LocationRestriction = if ((($FilterVMSKUs | Where-Object Name -EQ $SkuName).Restrictions.Type | Out-String).Contains("Location")){"NotAvailableInRegion"}else{"Available - No region restrictions applied" }
    $ZoneRestriction = if ((($FilterVMSKUs | Where-Object Name -EQ $SkuName).Restrictions.Type | Out-String).Contains("Zone")){"NotAvailableInZone: "+(((($FilterVMSKUs | Where-Object Name -EQ $SkuName).Restrictions.RestrictionInfo.Zones)| Where-Object {$_}) -join ",")}else{"Available - No zone restrictions applied"}

    $OutTable += New-Object PSObject -Property @{
        "Name" = $SkuName
        "Location" = $FilterAzureRegion
        "Applies to SubscriptionID" = $SubscriptionID
        "Subscription Restriction" = $LocationRestriction
        "Zone Restriction" = $ZoneRestriction
    }
}

$OutTable | Select-Object Name, Location, "Applies to SubscriptionID", "Subscription Restriction", "Zone Restriction" | Sort-Object -Property Name | Format-Table

Disconnect-AzAccount