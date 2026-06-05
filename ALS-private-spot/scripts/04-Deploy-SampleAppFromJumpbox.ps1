<#
.SYNOPSIS
    Deploys the sample app to AKS using AKS command invoke.
.DESCRIPTION
    Executes kubectl commands via `az aks command invoke` so private cluster networking
    does not block test deployment from the operator workstation.
.PARAMETER ResourceGroupName
    Resource group containing AKS.
.PARAMETER AksClusterName
    AKS cluster name.
.EXAMPLE
    .\04-Deploy-SampleAppFromJumpbox.ps1 -ResourceGroupName rg-demo -AksClusterName aks-demo
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AksClusterName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workingDir = Split-Path -Parent $PSCommandPath
$tempScript = Join-Path $workingDir "aks-demo-deploy.sh"

$bashScript = @"
cat <<'YAML' > /tmp/demo.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-web
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-web
  template:
    metadata:
      labels:
        app: demo-web
    spec:
      nodeSelector:
        kubernetes.azure.com/scalesetpriority: spot
      tolerations:
      - key: kubernetes.azure.com/scalesetpriority
        operator: Equal
        value: spot
        effect: NoSchedule
      containers:
      - name: web
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: demo-web
  namespace: demo
spec:
  selector:
    app: demo-web
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
YAML

kubectl apply -f /tmp/demo.yaml
kubectl get pods -n demo
kubectl get svc demo-web -n demo
"@

[System.IO.File]::WriteAllText($tempScript, ($bashScript -replace "`r`n", "`n"))

try {
    Write-Host "Deploying sample app using AKS command invoke..."
    az aks command invoke `
        --resource-group $ResourceGroupName `
        --name $AksClusterName `
        --file $tempScript `
        --command "bash aks-demo-deploy.sh"
}
finally {
    if (Test-Path $tempScript) {
        Remove-Item -Path $tempScript -Force
    }
}
