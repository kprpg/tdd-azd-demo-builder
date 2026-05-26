# Azure Arc For SQL Server: DBA Demo Script

## Demo Goal

Show Azure Arc from a DBA perspective in 15 to 20 minutes:

- why it matters
- what is immediately useful without paid add-ons
- where SQL Server 2016 ESUs fit
- how The Factory scales the approach

## Pre-Demo Setup

Have ready:

- 2 to 3 Arc-enabled servers already connected
- at least one SQL Server 2016 instance
- at least one newer SQL instance for contrast
- tags already applied for grouping
- permissions to view Azure Arc machines and SQL Server resources
- if available, one sample Azure Resource Graph query and one dashboard tile

## Opening Talk Track

"Most DBA teams still manage hybrid SQL estates through a combination of local tools, scripts, spreadsheets, and CMDB records. Azure Arc gives us a single management plane for servers and SQL instances without requiring those databases to move to Azure."

## Step 1: Show Azure Arc-Enabled Servers

What to show:

- Azure Arc > Machines
- machine status, region, resource group, tags
- one healthy connected machine and optionally one machine in a different environment

Talk track:

"This is the server-level foundation. Once a machine is Arc-enabled, it becomes an Azure resource with a consistent identity, policy surface, RBAC model, and operational hooks."

Audience takeaway:

- Arc starts with server onboarding
- hybrid machines become governable like Azure resources

## Step 2: Show SQL Server Enabled By Azure Arc

What to show:

- SQL Server - Azure Arc resources
- version, edition, number of cores, host operating system
- a SQL Server 2016 instance and a newer instance side by side

Talk track:

"This is the DBA-relevant layer. We move from generic server inventory to SQL-aware inventory and lifecycle visibility."

Audience takeaway:

- Arc is not just a server inventory tool
- it gives centralized SQL estate visibility

## Step 3: Show Free / Immediate DBA Value

What to show:

- tags and resource grouping
- Azure Resource Graph query or dashboard example
- SQL instance or database detail views
- migration readiness view if available

Talk track:

"Before we talk about anything paid, this is the immediate value: centralized inventory, consistent governance hooks, reporting, and a better operating picture of the estate."

Audience takeaway:

- there is useful value before ESU or other add-ons are enabled

## Step 4: Explain SQL Server 2016 ESU Readiness

What to show:

- a SQL Server 2016 resource
- its host and configuration context
- where ESU-related configuration would be managed

Talk track:

"For SQL Server 2016, Arc onboarding is the prerequisite. Once the server and SQL resource are visible here, we can make a governed decision: upgrade, migrate, retire, or temporarily place the workload on ESUs."

Audience takeaway:

- Arc first, ESU second
- ESU is a controlled exception path

## Step 5: Separate Paid Capabilities Clearly

What to say:

"Paid capabilities sit on top of the Arc foundation. That includes ESUs, some monitoring and security add-ons, and optional licensing models such as pay-as-you-go SQL Server. We want to reserve those for the workloads that justify them."

Optional items to mention:

- ESU licensing by v-core or p-core depending on hosting model
- Defender for Cloud / Defender for SQL
- AMA + Log Analytics backed monitoring experiences

Audience takeaway:

- the free and paid story is distinct and easier to govern

## Step 6: Land The Factory Story

What to say:

"The Factory is how we turn a pilot into an operating model. It should standardize discovery, classification, onboarding, SQL enablement, and governance so DBAs are not doing this one server at a time."

Describe the Factory flow:

1. Discover servers and SQL instances.
2. Classify SQL Server 2016 workloads.
3. Onboard selected servers to Azure Arc.
4. Enable SQL Server enabled by Azure Arc.
5. Apply tags, RBAC, and policy.
6. Roll out in waves.

Audience takeaway:

- The Factory is the scale mechanism
- it reduces inconsistency and improves governance

## Closing Talk Track

"The pilot objective is not just to connect servers. It is to prove that DBAs gain actionable estate visibility and that we can handle SQL Server 2016 support decisions rationally and repeatably."

## Optional Q&A Prep

- What ports and connectivity are required?
  Use outbound HTTPS over TCP 443, with proxy support if needed.
- Do we have to move databases to Azure?
  No. Arc brings Azure management to on-premises and multicloud SQL.
- Is Arc useful before we buy anything?
  Yes. Inventory, governance, and lifecycle visibility are immediate.
- Should all SQL 2016 servers get ESU?
  No. ESU should be limited to justified exception systems.

## Demo Query Snippets

Use these Azure Resource Graph queries during the demo if you want to show licensing posture directly from Arc resources.

### Arc License Resources

```kusto
Resources
| where type in~ (
  'microsoft.hybridcompute/licenses',
  'microsoft.azurearcdata/sqlserverlicenses',
  'microsoft.azurearcdata/sqlserveresulicenses'
)
| project subscriptionId, resourceGroup, type, name, location, properties
| order by type asc, name asc
```

### SQL Licensing Posture By Arc-Enabled SQL Instance

```kusto
Resources
| where type =~ 'microsoft.azurearcdata/sqlserverinstances'
| extend arcMachineName = tostring(split(tostring(properties.containerResourceId), '/')[8])
| project
  subscriptionId,
  resourceGroup,
  arcMachineName,
  sqlInstanceName = name,
  sqlVersion = tostring(properties.version),
  sqlEdition = tostring(properties.edition),
  hostLicenseType = coalesce(tostring(properties.licenseType), tostring(properties.hostLicenseType)),
  esuStatus = coalesce(tostring(properties.esuProfile.esuStatus), tostring(properties.esuStatus))
| order by arcMachineName asc, sqlInstanceName asc
```

### Windows ESU Assignment By Arc Machine

```kusto
Resources
| where type =~ 'microsoft.hybridcompute/machines/licenseprofiles'
| extend machineId = tostring(split(id, '/licenseProfiles')[0])
| extend machineName = tostring(split(machineId, '/')[8])
| project
  subscriptionId,
  resourceGroup,
  machineName,
  assignedLicense = coalesce(
    tostring(properties.esuProfile.assignedLicense),
    tostring(properties.esuProfile.assignedLicenseResourceId)
  ),
  esuEligibility = coalesce(
    tostring(properties.esuProfile.esuEligibility),
    tostring(properties.esuProfile.eligibility)
  ),
  esuAssignmentState = coalesce(
    tostring(properties.esuProfile.licenseAssignmentState),
    tostring(properties.esuProfile.assignmentState)
  )
| order by machineName asc
```
