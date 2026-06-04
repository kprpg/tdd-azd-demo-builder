<#
.SYNOPSIS
    Opens an SSH session to jumpbox VM through Azure Bastion.
.DESCRIPTION
    Uses Azure Bastion native SSH to connect to a private jumpbox VM without exposing
    a public IP. Use this to manage the private AKS cluster.
.PARAMETER ResourceGroupName
    Resource group containing the Bastion host and jumpbox VM.
.PARAMETER BastionName
    Azure Bastion resource name.
.PARAMETER JumpboxName
    Jumpbox VM name.
.PARAMETER JumpboxUsername
    Local admin username configured on jumpbox VM.
.PARAMETER SshPrivateKeyPath
    Path to the SSH private key that matches the jumpbox public key.
.EXAMPLE
    .\03-Open-BastionSession.ps1 -ResourceGroupName rg-demo -BastionName bastion-demo -JumpboxName vm-jumpbox -JumpboxUsername azureuser -SshPrivateKeyPath C:\Users\you\.ssh\id_rsa
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$BastionName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$JumpboxName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$JumpboxUsername,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SshPrivateKeyPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Resolving jumpbox VM resource ID..."
$jumpboxResourceId = az vm show `
    --resource-group $ResourceGroupName `
    --name $JumpboxName `
    --query id `
    --output tsv

if ([string]::IsNullOrWhiteSpace($jumpboxResourceId)) {
    throw "Unable to resolve jumpbox VM resource ID."
}

Write-Host "Starting Bastion SSH session..."
az network bastion ssh `
    --resource-group $ResourceGroupName `
    --name $BastionName `
    --target-resource-id $jumpboxResourceId `
    --auth-type ssh-key `
    --username $JumpboxUsername `
    --ssh-key $SshPrivateKeyPath
