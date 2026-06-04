<#
.SYNOPSIS
    Previews private AKS demo infrastructure deployment changes.
.DESCRIPTION
    Validates required CLIs, ensures Azure login, sets subscription and azd environment,
    then runs a non-destructive `azd provision --preview`.
.PARAMETER EnvironmentName
    Azure Developer CLI environment name.
.PARAMETER SubscriptionId
    Target Azure subscription ID.
.PARAMETER Location
    Azure region to use for deployment defaults.
.EXAMPLE
    .\01-Preview-Deployment.ps1 -EnvironmentName demo -Location eastus2
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$EnvironmentName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Location = "eastus2"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$scenarioRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

function Test-RequiredCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $command = Get-Command -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw "Required command '$Name' was not found in PATH."
    }
}

Write-Host "Validating prerequisites..."
Test-RequiredCommand -Name "az"
Test-RequiredCommand -Name "azd"

Write-Host "Checking Azure login..."
$account = az account show --output json | ConvertFrom-Json
if ($null -eq $account) {
    throw "Azure CLI is not logged in. Run 'az login' first."
}

if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
    Write-Host "Setting subscription: $SubscriptionId"
    az account set --subscription $SubscriptionId | Out-Null
}

Write-Host "Preparing azd environment: $EnvironmentName"
Push-Location $scenarioRoot
try {
    azd env select $EnvironmentName 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        azd env new $EnvironmentName | Out-Null
    }

    azd env set AZURE_LOCATION $Location | Out-Null

    Write-Host "Running azd provision preview..."
    azd provision --preview
}
finally {
    Pop-Location
}
