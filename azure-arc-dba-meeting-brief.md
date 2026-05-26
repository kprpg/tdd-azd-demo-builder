# Azure Arc For SQL Server: DBA Meeting Brief

## Objective

Align on how to use Azure Arc from a DBA perspective to:

- onboard a pilot group of database servers
- prepare for SQL Server 2016 Extended Security Updates (ESUs)
- demonstrate immediate free value versus paid capabilities
- scale the approach through The Factory

## Core Message

Azure Arc is the hybrid management control plane for SQL Server estate that remains outside Azure. For DBAs, the immediate value is centralized inventory, governance, and lifecycle visibility. ESUs for SQL Server 2016 are an important paid outcome, but they sit on top of Arc onboarding rather than replacing upgrade and modernization planning.

## What Is Required To Enable Azure Arc On A Pilot Group Of Database Servers?

Keep the pilot narrow and representative:

- 5 to 15 servers
- include SQL Server 2016 and at least one newer version
- include both easier candidates and one or two realistic production-like systems

Minimum requirements:

- an Azure subscription and resource group for Arc-managed resources
- outbound connectivity from each server to Azure Arc endpoints over TCP 443, directly or through a proxy
- local administrative rights to install the Azure Connected Machine agent
- clear ownership across DBA, infrastructure, and security teams
- tagging, RBAC, and naming standards for the pilot
- SQL Server enabled by Azure Arc after the machine onboarding step

Pilot success criteria:

- all target machines onboard consistently
- SQL instances become visible in Azure
- DBAs can see useful instance metadata and estate inventory
- governance and access controls are acceptable
- the onboarding path is documented well enough to scale

## What Is Required To Enable ESUs For SQL Server 2016 On-Premises?

The required operational sequence is:

1. Connect the host to Azure Arc.
2. Enable SQL Server enabled by Azure Arc.
3. Confirm the SQL 2016 instance is visible and correctly classified.
4. Enable the appropriate ESU subscription path and billing model.

Key requirements:

- eligible SQL Server 2016 deployment on a supported host
- Arc-enabled server onboarding complete
- SQL Server enabled by Azure Arc configured and healthy
- Azure subscription available for ESU administration and billing
- active Software Assurance, SQL Server subscription, or acceptance of pay-as-you-go billing through Azure
- an internal process to classify servers as upgrade, migrate, retire, or ESU

Important DBA talking points:

- Arc is the prerequisite control plane.
- ESUs are a temporary risk-management option, not the default lifecycle strategy.
- ESUs can be licensed by virtual cores, physical cores on a non-virtualized host, or by physical cores with unlimited virtualization depending on how the estate is hosted.
- For Windows and Arc-managed SQL, keeping connectivity healthy matters because long disconnects can affect ESU continuity and billing behavior.

## Demo Of Free And Paid Azure Arc Capabilities From A DBA Perspective

Free or immediate value to show first:

- centralized inventory of Arc-enabled servers
- centralized inventory of SQL instances enabled by Azure Arc
- version, edition, core count, host OS, and database visibility
- Azure Resource Graph queries and dashboards for SQL estate reporting
- governance hooks through tags, RBAC, and policy
- migration readiness assessment visibility
- the ability to run custom T-SQL collection at scale through Arc-enabled servers Run Command

Paid or add-on capabilities to call out separately:

- ESU subscriptions for out-of-support SQL Server versions
- best practices assessment where license type applies
- performance dashboards and monitoring scenarios that rely on AMA and Log Analytics
- Microsoft Defender for Cloud / Defender for SQL scenarios
- SQL Server pay-as-you-go licensing through Azure Arc

## How Can We Leverage The Factory?

The Factory should become the repeatable operating model for hybrid SQL governance rather than a one-time deployment exercise.

Use The Factory to standardize:

- discovery of SQL Server estate
- pilot candidate selection
- Arc onboarding and SQL extension enablement
- tagging, RBAC, and policy application
- SQL 2016 classification into upgrade, migrate, retire, or ESU
- rollout waves and reporting

Recommended Factory workflow:

1. Discover the SQL estate.
2. Classify legacy SQL Server workloads.
3. Onboard the pilot to Azure Arc.
4. Enable SQL Server enabled by Azure Arc.
5. Validate visibility, governance, and support posture.
6. Scale in waves with a repeatable checklist.

## Recommended Outcome From The Meeting

Leave the meeting with:

- an agreed pilot server list
- a named ownership model
- a connectivity and permissions checklist
- a SQL Server 2016 decision matrix
- a Factory-led scale-out plan

## Reference Notes

The guidance in this brief aligns with current Microsoft Learn documentation for Azure Arc-enabled servers, SQL Server enabled by Azure Arc, and SQL Server ESUs enabled by Azure Arc as of May 2026.

## Appendix: Azure Resource Graph Queries For Arc Licensing

These queries are intended for Azure Resource Graph Explorer and focus on Azure Arc licensing visibility for SQL Server and Windows Server.

### All Arc License Resources

This query lists the Arc-side license resources for Windows Server ESU, SQL Server licensing, and SQL Server ESU licensing.

```kusto
Resources
| where type in~ (
    'microsoft.hybridcompute/licenses',
    'microsoft.azurearcdata/sqlserverlicenses',
    'microsoft.azurearcdata/sqlserveresulicenses'
)
| extend licenseFamily = case(
    type =~ 'microsoft.hybridcompute/licenses', 'Windows Server ESU',
    type =~ 'microsoft.azurearcdata/sqlserverlicenses', 'SQL Server License',
    type =~ 'microsoft.azurearcdata/sqlserveresulicenses', 'SQL Server ESU License',
    'Other'
)
| extend edition = coalesce(
    tostring(properties.licenseDetails.edition),
    tostring(properties.edition),
    tostring(properties.sku.name)
)
| extend licenseModel = coalesce(
    tostring(properties.licenseDetails.type),
    tostring(properties.licenseType),
    tostring(properties.billingPlan)
)
| extend scopeType = coalesce(
    tostring(properties.scopeType),
    tostring(properties.licenseDetails.scopeType)
)
| extend coreCount = coalesce(
    tostring(properties.physicalCores),
    tostring(properties.size),
    tostring(properties.licenseDetails.processors),
    tostring(properties.licenseDetails.cores)
)
| extend status = coalesce(
    tostring(properties.activationState),
    tostring(properties.state),
    tostring(properties.provisioningState)
)
| project
    subscriptionId,
    resourceGroup,
    licenseFamily,
    name,
    location,
    edition,
    licenseModel,
    scopeType,
    coreCount,
    status,
    id
| order by licenseFamily asc, name asc
```

### SQL Licensing On Arc-Enabled SQL Instances

This query is the most DBA-friendly view because it shows the SQL instance and the Arc-reported host licensing posture.

```kusto
Resources
| where type =~ 'microsoft.azurearcdata/sqlserverinstances'
| extend arcMachineId = tostring(properties.containerResourceId)
| extend arcMachineName = tostring(split(arcMachineId, '/')[8])
| extend sqlEdition = tostring(properties.edition)
| extend sqlVersion = tostring(properties.version)
| extend hostLicenseType = coalesce(
    tostring(properties.licenseType),
    tostring(properties.hostLicenseType)
)
| extend usePhysicalCoreLicense = coalesce(
    tostring(properties.usePhysicalCoreLicense),
    tostring(properties.hostConfiguration.usePhysicalCoreLicense)
)
| extend usePhysicalEsuCoreLicense = coalesce(
    tostring(properties.usePhysicalEsuCoreLicense),
    tostring(properties.hostConfiguration.usePhysicalEsuCoreLicense)
)
| extend esuStatus = coalesce(
    tostring(properties.esuProfile.esuStatus),
    tostring(properties.esuStatus),
    tostring(properties.sqlServerConfiguration.esuStatus)
)
| project
    subscriptionId,
    resourceGroup,
    arcMachineName,
    sqlInstanceName = name,
    sqlVersion,
    sqlEdition,
    hostLicenseType,
    usePhysicalCoreLicense,
    usePhysicalEsuCoreLicense,
    esuStatus,
    arcMachineId,
    id
| order by arcMachineName asc, sqlInstanceName asc
```

### Windows Server ESU License Posture On Arc-Enabled Machines

This query focuses on the Arc machine license profile resource, where Windows Server ESU assignment state is exposed.

```kusto
Resources
| where type =~ 'microsoft.hybridcompute/machines/licenseprofiles'
| extend machineId = tostring(split(id, '/licenseProfiles')[0])
| extend machineName = tostring(split(machineId, '/')[8])
| extend assignedLicenseResource = coalesce(
    tostring(properties.esuProfile.assignedLicense),
    tostring(properties.esuProfile.assignedLicenseResourceId),
    tostring(properties.assignedLicense)
)
| extend esuEligibility = coalesce(
    tostring(properties.esuProfile.esuEligibility),
    tostring(properties.esuProfile.eligibility),
    tostring(properties.esuProfile.serverType)
)
| extend esuAssignmentState = coalesce(
    tostring(properties.esuProfile.licenseAssignmentState),
    tostring(properties.esuProfile.assignmentState),
    tostring(properties.provisioningState)
)
| project
    subscriptionId,
    resourceGroup,
    machineName,
    assignedLicenseResource,
    esuEligibility,
    esuAssignmentState,
    machineId,
    id
| order by machineName asc
```

### Combined Machine View For Windows And SQL Licensing

This query joins Arc machines with SQL instances and Windows machine license profiles into a single operational view.

```kusto
Resources
| where type =~ 'microsoft.hybridcompute/machines'
| project
    machineId = id,
    machineName = name,
    subscriptionId,
    resourceGroup,
    location,
    osName = tostring(properties.osName),
    osVersion = tostring(properties.osVersion),
    status = tostring(properties.status)
| join kind=leftouter (
    Resources
    | where type =~ 'microsoft.azurearcdata/sqlserverinstances'
    | extend machineId = tostring(properties.containerResourceId)
    | project
        machineId,
        sqlInstanceName = name,
        sqlEdition = tostring(properties.edition),
        sqlVersion = tostring(properties.version),
        sqlLicenseType = coalesce(
            tostring(properties.licenseType),
            tostring(properties.hostLicenseType)
        ),
        sqlEsu = coalesce(
            tostring(properties.esuProfile.esuStatus),
            tostring(properties.esuStatus)
        )
) on machineId
| join kind=leftouter (
    Resources
    | where type =~ 'microsoft.hybridcompute/machines/licenseprofiles'
    | extend machineId = replace(@'/licenseProfiles.*$', '', id)
    | project
        machineId,
        windowsAssignedLicense = coalesce(
            tostring(properties.esuProfile.assignedLicense),
            tostring(properties.esuProfile.assignedLicenseResourceId)
        ),
        windowsEsuEligibility = coalesce(
            tostring(properties.esuProfile.esuEligibility),
            tostring(properties.esuProfile.eligibility)
        ),
        windowsEsuAssignmentState = coalesce(
            tostring(properties.esuProfile.licenseAssignmentState),
            tostring(properties.esuProfile.assignmentState)
        )
) on machineId
| project
    subscriptionId,
    resourceGroup,
    machineName,
    location,
    osName,
    osVersion,
    status,
    sqlInstanceName,
    sqlVersion,
    sqlEdition,
    sqlLicenseType,
    sqlEsu,
    windowsAssignedLicense,
    windowsEsuEligibility,
    windowsEsuAssignmentState
| order by machineName asc, sqlInstanceName asc
```

### Schema Discovery Query

If any of the licensing fields are blank in a given tenant, run this query first to inspect the available property shape.

```kusto
Resources
| where type in~ (
    'microsoft.hybridcompute/licenses',
    'microsoft.hybridcompute/machines/licenseprofiles',
    'microsoft.azurearcdata/sqlserverinstances',
    'microsoft.azurearcdata/sqlserverlicenses',
    'microsoft.azurearcdata/sqlserveresulicenses'
)
| project type, name, id, properties
| take 50
```

### Notes

- `microsoft.hybridcompute/licenses` is the Windows Server Arc ESU license resource.
- `microsoft.hybridcompute/machines/licenseprofiles` is the per-machine Windows ESU assignment view.
- `microsoft.azurearcdata/sqlserverlicenses` and `microsoft.azurearcdata/sqlserveresulicenses` are SQL Arc license resources.
- `microsoft.azurearcdata/sqlserverinstances` is the per-instance view that is usually the most useful for DBA reporting.
