[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$tenantID,
    [Parameter(Mandatory)][string]$subscriptionID
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

$sp = Get-AzADServicePrincipal -DisplayName 'Parallels RAS'
$spAssignedScopes = Get-AzRoleAssignment -ObjectId $sp.ID | Select Scope, RoleDefinitionName

foreach ($scope in $spAssignedScopes) {
    Remove-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName $scope.RoleDefinitionName -Scope $scope.Scope
}

Remove-AzADServicePrincipal -DisplayName $sp.DisplayName

Disconnect-AzAccount