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

New-AzRoleAssignment -ApplicationId $sp.AppId -RoleDefinitionName 'Reader' -Scope "/subscriptions/$subscriptionID"
New-AzRoleAssignment -ApplicationId $sp.AppId -RoleDefinitionName 'User Access Administrator' -Scope "/subscriptions/$subscriptionID"

foreach ($rg in $resourceGroups) {
    New-AzRoleAssignment -ResourceGroupName $rg -ApplicationId $sp.AppId -RoleDefinitionName 'Contributor'
}

Disconnect-AzAccount

Write-Host "Mandanten-ID:" $tenantID -ForegroundColor Yellow
Write-Host "Abonnement-ID:" $subscriptionID -ForegroundColor Yellow
Write-Host "Anwendungs-ID:" $sp.AppId -ForegroundColor Yellow
Write-Host "Anwendungsschluessel:" $sp.PasswordCredentials.SecretText -ForegroundColor Yellow