# Trainer-Demo-Deploy - Azure Demo Builder

An agent-driven workflow for building, deploying, and demonstrating Azure infrastructure scenarios — powered by GitHub Copilot custom agents and Azure Developer CLI (`azd`).

## What Is This?

[Trainer-Demo-Deploy](https://aka.ms/trainer-demo-deploy) Azure Demo Builder automates the end-to-end lifecycle of Azure demo environments. Describe the Azure scenario you want to build in natural language, and a pipeline of specialized AI agents handles requirements gathering, architecture design, Bicep code generation, deployment, and demo guide creation — all within VS Code.

Instead of manually writing Bicep templates, configuring `azd`, and preparing demo scripts, you interact with a single **Conductor** agent that orchestrates specialized agents through the full workflow.

## How It Works

The workflow is a multi-step pipeline. Each step is handled by a dedicated agent that produces versioned artifacts in `scenario/{project}/`. The Conductor coordinates handoffs automatically.

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ 02. Require- │───▶│ 03. Archi-   │───▶│ 04. Design   │
│    ments     │    │    tect      │    │  (Diagrams)  │
└──────────────┘    └──────────────┘    └──────────────┘
                                              │
        ┌─────────────────────────────────────┘
        ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  05. Bicep   │───▶│ 05b. Dev*    │───▶│  06. Deploy  │
│  (IaC Gen)   │    │ (Sample App) │    │   (azd up)   │
└──────────────┘    └──────────────┘    └──────────────┘
                                              │
        ┌─────────────────────────────────────┘
        ▼
┌──────────────┐    ┌──────────────┐
│  07. Demo    │───▶│ 08. Contri-  │
│    Guide     │    │   bute*      │
└──────────────┘    └──────────────┘

* = conditional / user-invoked
```

| Step | Agent            | What It Does                                                   | Key Output                                            |
| ---- | ---------------- | -------------------------------------------------------------- | ----------------------------------------------------- |
| 02   | **Validations**  | Parses your scenario description into structured requirements  | `01-requirements.md`                                  |
| 03   | **Architect**    | Recommends Azure services, SKUs, and documents trade-offs      | `02-architecture-assessment.md`                       |
| 04   | **Diagrammer**   | Generates Python-based architecture diagrams and ADRs          | `03-architect-diagram.py`, `03-architect-diagram.png` |
| 05   | **Bicep**        | Runs governance discovery, generates AVM-first Bicep templates | `infra/main.bicep`, `04-implementation-plan.md`       |
| 05b  | **Development**  | Scaffolds a .NET 10 sample webapp with industry seed data      | `src/`, `07-webapp-summary.md`                        |
| 06   | **Deploy**       | Runs `azd up` with what-if analysis and validates deployment   | `06-deployment-summary.md`                            |
| 07   | **DemoGuide**    | Produces an audience-aware demo runbook with talking points    | `demoguide/demoguide.md`                              |
| 08   | **Contribute**   | Publishes scenario to a standalone repo and registers upstream | Standalone repo + registry draft PR                   |

All artifacts land in `scenario/{project}/`, giving you a self-contained, version-controlled demo package.

## Prerequisites

| Requirement                                                                                                     | Purpose                                   |
| --------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| [VS Code](https://code.visualstudio.com/) (1.100+)                                                              | IDE with agent support                    |
| [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat) (active subscription) | Powers the AI agents                      |
| [Azure Developer CLI (`azd`)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)      | Deploys infrastructure                    |
| [Azure CLI (`az`)](https://learn.microsoft.com/cli/azure/install-azure-cli)                                     | Governance discovery and authentication   |
| [Bicep CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install)                             | Template compilation and linting          |
| [Python 3.10+](https://www.python.org/)                                                                         | Diagram generation                        |
| [Graphviz](https://graphviz.org/download/)                                                                      | Required by the `diagrams` Python library |
| [GitHub CLI (`gh`)](https://cli.github.com/)                                                                     | Fork, branch, PR, and issue operations (required for contributing) |
| An Azure subscription                                                                                           | Target for deployments                    |

### Recommended VS Code Extensions

The workspace includes an [extensions.json](.vscode/extensions.json) with recommendations. Key ones:

- `ms-azuretools.vscode-azure-mcp-server` — Azure MCP server for resource queries
- `ms-azuretools.vscode-bicep` — Bicep language support
- `ms-vscode.copilot-mermaid-diagram` — Mermaid diagram rendering in chat

### Python Dependencies

```bash
pip install -r requirements.txt
```

## Getting Started

### 1. Clone and Open

```bash
git clone https://github.com/petender/tdd-azd-demo-builder.git
cd tdd-azd-demo-builder
code .
```

### 2. Sign In to Azure

```bash
az login
azd auth login
```

### 3. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 4. Open Copilot Chat and Run

Open the Copilot Chat panel (`Ctrl+Shift+I`), select the **01-conductor** agent, and describe your scenario. The Conductor handles everything from there.

#### Example Prompt

> I want to build an Azure demo scenario with a web app hosted on Azure App Service, connected to an Azure SQL Database, with secrets stored in Key Vault, and monitoring via Application Insights. The web app should use managed identity to access both the database and Key Vault. Include a VNet with private endpoints for the SQL database and Key Vault.

The agent will:

1. Parse your description into structured requirements
2. Assess the architecture (services, SKUs, trade-offs)
3. Generate architecture diagrams
4. Produce governance-aware Bicep templates using Azure Verified Modules
5. Deploy to Azure via `azd up`
6. Create a step-by-step demo guide

#### More Example Prompts

**Hub-spoke network with VMs and Bastion:**

> Build a demo with a web VM and SQL VM in separate subnets, connected through Azure Firewall, with Bastion for secure access and Key Vault for password management.

**Containerized microservices:**

> Create an Azure Container Apps demo with three microservices, an Azure Container Registry, Application Insights for monitoring, and a Service Bus for async messaging between services.

**Serverless event-driven:**

> I need a serverless demo with Azure Functions triggered by Event Grid, writing to Cosmos DB, with API Management as the front door and Application Insights for observability.

## Project Structure

```
.github/
├── agents/                    # Agent definitions (one per workflow step)
│   ├── 01-conductor.agent.md
│   ├── 02-validation.agent.md
│   ├── 03-architect.agent.md
│   ├── 04-diagrammer.agent.md
│   ├── 05-bicep.agent.md
│   ├── 05b-development.agent.md
│   ├── 06-deploy.agent.md
│   ├── 07-demoguide.agent.md
│   └── 08-contribute.agent.md
├── instructions/              # File-type coding standards (Bicep, Markdown, Python, etc.)
└── skills/                    # Reusable knowledge consumed by agents
    ├── SKILL.md               # Consolidated skill (defaults, AVM, patterns, diagrams)
    ├── azure-artifacts/       # Artifact templates
    ├── azure-deploy/          # Deployment patterns
    ├── azure-diagrams/        # Diagram generation guides
    └── azure-validate/        # Pre/post deployment validation

scenario/                      # Generated demo projects (one folder per scenario)
├── webvm-sqlvm-bastion-fw/    # Example: VMs + Bastion + Firewall
│   ├── 01-requirements.md
│   ├── 02-architecture-assessment.md
│   ├── 03-architect-diagram.py
│   ├── 04-implementation-plan.md
│   ├── 06-deployment-summary.md
│   ├── demoguide/demoguide.md
│   ├── azure.yaml
│   ├── src/                   # Sample webapp (if generated)
│   └── infra/
│       ├── main.bicep
│       ├── main.bicepparam
│       └── modules/
└── azure-container-scenarios/ # Example: Container Apps
    └── ...
```

## Key Design Decisions

- **AVM-first**: The Bicep agent always uses [Azure Verified Modules](https://aka.ms/avm) when available, falling back to raw Bicep only when no AVM module exists.
- **Deployer data plane access**: When RBAC-enabled resources are deployed (Key Vault, Storage, etc.), the deploying user automatically receives data plane role assignments so they can immediately interact with the resources.
- **Convention over configuration**: Default region (`eastus2`), naming conventions (CAF-aligned), security baseline (TLS 1.2, HTTPS-only, managed identity), and tagging are baked into the skills and instructions.

## Teardown

To remove all deployed resources for a scenario:

```bash
cd scenario/{project-name}
azd down --force --purge
```

## Understanding the Agent Architecture

New to GitHub Copilot custom agents? See
[AGENTSEXPLAINED.md](AGENTSEXPLAINED.md) for a technical deep-dive into how
agents, skills, instructions, and prompts work together — including how to
add your own agents, skills, and coding standards to the workflow.

## Contributing

We welcome scenario contributions from the community! The contribution model publishes each scenario as a **standalone `azd`-compatible repo** in your GitHub account and registers it in the upstream project's scenario registry.

### Prerequisites for Contributing

| Requirement | Purpose |
|---|---|
| [GitHub CLI (`gh`)](https://cli.github.com/) | **Required.** The Contribute agent uses `gh` to create repos, fork the upstream project, and open PRs. Install and authenticate with `gh auth login` before contributing. |
| Completed scenario (Steps 1–6) | Your scenario folder under `scenario/` must contain the required artifacts before contributing. |

### Agent-Assisted (Recommended)

After completing the agent workflow (Steps 1–6), invoke the **08-Contribute** agent
in Copilot Chat. It will:

1. **Validate** your scenario artifacts for completeness (`infra/main.bicep`, `azure.yaml`, `README.md`)
2. **Create a standalone repo** named `tdd-azd-{scenario}` in your GitHub account (asks for approval first)
3. **Populate the repo** with publishable artifacts (`infra/`, `src/`, `demoguide/`, `azure.yaml`, `README.md`) as a flat `azd`-compatible project
4. **Register upstream** by opening a draft PR that adds your scenario to `scenarios/registry.json`

The agent performs a sensitive-data check before copying — it will refuse to proceed if `.azure/`, `.env`, `bin/`, `obj/`, `publish/`, or `applogs/` files would be included.

### Manual

1. Install and authenticate the [GitHub CLI](https://cli.github.com/): `gh auth login`
2. Create a public repo named `tdd-azd-{your-scenario-name}` in your GitHub account
3. Copy the publishable artifacts from `scenario/{project}/` to the repo root:
   - `infra/` (Bicep templates), `azure.yaml`, `README.md`
   - `src/` (if webapp), `demoguide/` (if demo guide was generated)
4. Ensure no sensitive files are included (`.azure/`, `.env`, `bin/`, `obj/`)
5. Fork this repo, add your scenario to `scenarios/registry.json`, and open a draft PR

### Project Structure

1. **Agents** live in `.github/agents/` — each file defines one workflow step
2. **Skills** live in `.github/skills/` — shared knowledge that agents reference
3. **Instructions** live in `.github/instructions/` — file-type specific coding standards

To modify agent behavior, edit the corresponding `.agent.md` file. To change
patterns or defaults that apply across agents, update `SKILL.md` or the
relevant instruction file.

## License

MIT
