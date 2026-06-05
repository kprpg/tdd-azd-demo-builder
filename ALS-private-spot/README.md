## Private AKS + Bastion + Spot Demo

This folder contains **deployment scripts and runbook guidance** for a private AKS demo with:

- Private AKS control plane
- Azure Bastion access through a private jumpbox VM
- Cost-focused node pools (system + Spot user pool)
- Sample app deployment to the Spot user pool

> [!IMPORTANT]
> These scripts are for execution when you are ready. They do **not** deploy anything automatically.

## Architecture diagram

```mermaid
flowchart LR
    A[Operator Workstation] -->|az login / azd| B[Azure Subscription]
    B --> C[Resource Group]
    C --> D[VNet]
    D --> E[AzureBastionSubnet]
    D --> F[Jumpbox Subnet]
    D --> G[AKS Subnet]
    E --> H[Azure Bastion]
    H --> I[Jumpbox VM (Private IP)]
    I -->|kubectl + az| J[Private AKS API]
    J --> K[System Node Pool]
    J --> L[Spot User Node Pool]
    L --> M[Sample App Pods]
```

## Folder layout

| Path | Purpose |
| --- | --- |
| `scripts/01-Preview-Deployment.ps1` | Validate prerequisites and preview infra changes |
| `scripts/02-Deploy-PrivateAksDemo.ps1` | Deploy infra and app scaffolding with `azd up` |
| `scripts/03-Open-BastionSession.ps1` | Open SSH session to jumpbox through Azure Bastion |
| `scripts/04-Deploy-SampleAppFromJumpbox.ps1` | Push sample app using `az aks command invoke` |
| `k8s/sample-app.yaml` | Reference manifest for Spot-targeted sample app |
| `azure.yaml` | azd project definition |
| `infra/main.bicep` | Infrastructure template for private AKS + Bastion + jumpbox |
| `plan.md` | Planning document for this scenario |

## Execution flow

Run the scripts in this order from repository root:

1. `.\ALS-private-spot\scripts\01-Preview-Deployment.ps1 -EnvironmentName <env> -Location eastus2`
2. `.\ALS-private-spot\scripts\02-Deploy-PrivateAksDemo.ps1 -EnvironmentName <env>`
3. `.\ALS-private-spot\scripts\03-Open-BastionSession.ps1 -ResourceGroupName <rg> -BastionName <bastion> -JumpboxName <vm> -JumpboxUsername <user>`
4. `.\ALS-private-spot\scripts\04-Deploy-SampleAppFromJumpbox.ps1 -ResourceGroupName <rg> -AksClusterName <aks>`

## What each script does

### 1) Preview only

- Checks `az`, `azd`, and login state
- Selects subscription
- Creates/selects azd environment
- Runs `azd provision --preview` (safe dry run)

### 2) Deploy

- Uses the same azd environment
- Executes `azd up` to provision resources

### 3) Connect through Bastion

- Uses native Bastion SSH to jumpbox private VM
- Keeps AKS private endpoint inaccessible from public internet

### 4) Deploy sample app (private cluster safe path)

- Uses `az aks command invoke` to run kubectl server-side
- Applies a Spot-targeted demo deployment and service

## How to view and play with the cluster

Once connected to jumpbox:

```powershell
az aks get-credentials --resource-group <rg> --name <aks> --overwrite-existing
kubectl get nodes -o wide
kubectl get pods -A
kubectl get pods -n demo -o wide
kubectl get svc -n demo
kubectl describe node <spot-node-name>
```

To scale and observe scheduling:

```powershell
kubectl scale deployment demo-web --replicas=3 -n demo
kubectl get pods -n demo -o wide
kubectl describe pod <pod-name> -n demo
```

To clean app resources:

```powershell
kubectl delete namespace demo
```

To remove all deployed Azure resources:

```powershell
azd down
```

## Latest validated run

The deployment and test run were completed with these values:

| Item | Value |
| --- | --- |
| Subscription | `30da07dd-f37a-4091-be7a-a3484ece651d` |
| Resource group | `rg-alspspotw3` |
| Region | `westus3` (fallback due eastus2 spot capacity issue) |
| AKS cluster | `aks-als-private-spot-alspspotw3` |
| Bastion | `bas-als-private-spot-alspspotw3` |
| Jumpbox VM | `vm-jumpbox-alspspotw3` |
| Spot node pool scheduling label | `kubernetes.azure.com/scalesetpriority=spot` |
| Sample service external IP | `135.234.70.4` |

Validation executed:

1. ARM deployment succeeded for network, Bastion, jumpbox, and private AKS.
2. Sample app was deployed with Spot node selector and toleration.
3. `kubectl wait --for=condition=available deployment/demo-web -n demo` succeeded.
4. Service `demo-web` received an external LoadBalancer IP.

## Notes

- Spot nodes can be evicted at any time; keep demo workloads stateless.
- If Spot capacity is unavailable in region, deploy still succeeds but workload behavior may vary.
- You can tune user node pool min/max and VM size in infra parameters for cost vs stability.
