[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$tenantID,
    [Parameter(Mandatory)][string]$subscriptionID,
    [Parameter(Mandatory)][string[]]$resourceGroups
)

$requiredPSModules = 'Az.Accounts','Az.Resources'

foreach ($psModule in $requiredPSModules) {
    if (Get-Module -Name $psModule) {
        Write-Host "Required PowerShell Module $psModule is installed. Importing it ..." -ForegroundColor Yellow
        Import-Module -Name $psModule
    }
    else {
        Write-Host "Required PowerShell Module $psModule is not installed. Installing..." -ForegroundColor Yellow
        Install-Module -Name $psModule -Verbose
        Write-Host "Importing $psModule ..."
        Import-Module -Name $psModule
    }
}

Connect-AzAccount -TenantId $tenantID -SubscriptionId $subscriptionID

$sp = New-AzADServicePrincipal -DisplayName 'Parallels RAS'

New-AzRoleAssignment -ApplicationId $sp.AppId -RoleDefinitionName 'User Access Administrator' -Scope "/subscriptions/$subscriptionID"

# Microsoft Graph
Add-AzADAppPermission -ApplicationId $sp.AppId -ApiId 00000003-0000-0000-c000-000000000000 -PermissionId 5b567255-7703-4780-807c-7be8301ae99b -Type Role # Application - Group.Read.All
Add-AzADAppPermission -ApplicationId $sp.AppId -ApiId 00000003-0000-0000-c000-000000000000 -PermissionId df021288-bdef-4463-88db-98f22de89214 -Type Role # Application - Users.Read.All

foreach ($rg in $resourceGroups) {
    New-AzRoleAssignment -ResourceGroupName $rg -ApplicationId $sp.AppId -RoleDefinitionName 'Contributor'
}

Disconnect-AzAccount

Write-Host "Tenant ID:" $tenantID -ForegroundColor Yellow
Write-Host "Subscription ID:" $subscriptionID -ForegroundColor Yellow
Write-Host "Application (client) ID:" $sp.AppId -ForegroundColor Yellow
Write-Host "Application client secret:" $sp.PasswordCredentials.SecretText -ForegroundColor Yellow
Write-Host ">> You need to grant admin consent via Azure Portal because Azure PowerShell doesn't support it yet!" -ForegroundColor Red