## Objective

Create a deployable demo design for a **private AKS cluster** with:

- Azure Bastion access path through a private jumpbox VM
- Lowest-cost viable **system** node pool
- Lowest-cost viable **user** node pool configured as **Spot**
- Sample application deployment targeted to the Spot user pool

No resources will be created in this step.

## Scope and boundaries

- In scope: architecture, IaC/deployment plan, configuration defaults, and validation plan.
- Out of scope: running `azd up`, provisioning Azure resources, and live deployment execution.

## Proposed architecture

1. Create a spoke VNet with dedicated subnets for AKS nodes, AzureBastionSubnet, and jumpbox VM.
2. Deploy private AKS with private API endpoint and managed identity.
3. Deploy Azure Bastion and a private jumpbox VM (no public IP on jumpbox).
4. Install `kubectl` and `az` on jumpbox to manage AKS privately.
5. Add a Spot-enabled user pool and pin sample workload to that pool.

## Cost-optimized defaults

- Region default: `eastus2` (override allowed if SKU/Spot capacity is constrained).
- System pool:
  - Min count: 1
  - VM size: lowest-cost SKU that satisfies AKS system pool minimums in target region
- User Spot pool:
  - Min count: 0
  - Max count: 2
  - Priority: Spot
  - Eviction policy: Delete
  - Max price: `-1` (pay up to on-demand ceiling)

## Implementation work plan

1. Scaffold `generated-scenarios/ALS-private-spot/` with `azure.yaml` and `infra/`.
2. Author Bicep modules for network, Bastion, jumpbox VM, and private AKS.
3. Configure AKS node pools (system + Spot user) with cost-focused defaults.
4. Add sample app manifests using nodeSelector/tolerations for Spot pool scheduling.
5. Wire parameters/tags/naming and diagnostics per project standards.
6. Document deploy, bastion access flow, validation steps, and teardown (`azd down`).

## Validation plan (no deployment yet)

- Run template validation only:
  - `bicep build`
  - `bicep lint`
  - `azd provision --preview`
- Confirm parameters and outputs are complete for later `azd up`.

## Risks and mitigations

- Spot interruption risk: keep demo app stateless and replica-ready.
- Region SKU mismatch: allow VM SKU override parameter per node pool.
- Private DNS/routing gaps: include explicit private DNS linkage and subnet rules in IaC.

## Deliverables in this planning phase

- `ALS-private-spot/plan.md` (this file)
- Ready-to-execute implementation backlog for a later deployment phase
