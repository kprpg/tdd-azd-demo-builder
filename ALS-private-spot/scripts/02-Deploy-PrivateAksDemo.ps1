<#
.SYNOPSIS
    Deploys the private AKS demo environment with azd.
.DESCRIPTION
    Selects the target azd environment and runs `azd up` for full deployment.
.PARAMETER EnvironmentName
    Azure Developer CLI environment name.
.PARAMETER SubscriptionId
    Target Azure subscription ID.
.EXAMPLE
    .\02-Deploy-PrivateAksDemo.ps1 -EnvironmentName demo
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$EnvironmentName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$scenarioRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
    Write-Host "Setting subscription: $SubscriptionId"
    az account set --subscription $SubscriptionId | Out-Null
}

Write-Host "Selecting azd environment: $EnvironmentName"
Push-Location $scenarioRoot
try {
    azd env select $EnvironmentName | Out-Null

    Write-Host "Deploying with azd up..."
    azd up --no-prompt
}
finally {
    Pop-Location
}
