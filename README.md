# Microsoft 365 Cloud-Only Tenant-to-Tenant Migration Toolkit

**Engineering starter release — reviewed against Microsoft documentation on 2026-10-29.**

Tenant **A** (source) -> Tenant **B** (target), cloud-only users. Entra cloud IDs are **object IDs (GUIDs), not on-prem AD SIDs**; identity mapping must use those object IDs. Provides reproducible tenant discovery, migration readiness analysis, explicit identity mapping, Microsoft Graph migration orchestration, and documented workstreams for **every major M365 workload**. **This is not a turnkey, fully automated tenant migration:** Microsoft does not expose universal supported tenant-to-tenant move APIs for every service. The toolkit deliberately blocks unsupported or unapproved operations.

## What works today

| Component | Implementation status | Mutation? |
|---|---|---|
| Microsoft Graph inventory (users, IDs, groups, applications, enterprise apps, license SKUs, devices, Intune configuration, Conditional Access) | Implemented; collection requires delegated Graph access | No |
| Exchange, Teams and SharePoint inventory | Implemented; opt-in modules and admin roles required | No |
| Create explicit staging user map | Implemented; does **not** create target users | No |
| Create target cloud MailUsers | Approval-gated Exchange Online + Graph script; needs verified source SMTP; creates unlicensed MailUsers, disables sign-in | Only with explicit approval |
| Native CTIM identity mapping | Approved staged wrapper: source copy, target accept, map, write; administrative setup required first | Explicit gated steps |
| Readiness checks / license and workload plan | Implemented, offline tests included | No |
| Native Migration Orchestrator for Exchange, OneDrive, Teams chats/meetings | PowerShell Graph **beta** wrapper; *only after* Microsoft-defined tenant prerequisites/identity mapping/license gates are satisfied | Only with explicit `-Execute` and approval phrase |
| SharePoint cross-tenant site move | Official cmdlet runbook, licensing/EA gate | Human-controlled |
| Entra apps, service principals, policies, Intune settings | Discover/export, dependency mapping; controlled recreation only after review | Human-controlled |
| Devices, Power Platform, Fabric, Purview, security, smaller workloads | Service-specific runbook, blockers and vendor paths | Human-controlled |

## Requirements

- PowerShell 7.4+ recommended; Microsoft Graph PowerShell (`Microsoft.Graph.Authentication`), and for native orchestration `Microsoft.Graph.Beta.Migrations` (beta API; verify production suitability with Microsoft); optional `ExchangeOnlineManagement`, `MicrosoftTeams`, and `Microsoft.Online.SharePoint.PowerShell` (SharePoint module compatibility may require Windows PowerShell).
- Two independent commercial Microsoft 365 tenants, admin authorization in both, target staging `*.onmicrosoft.com` domain; approved migration scope, change control, legal hold review, licensed accounts, DNS access, and a backup/retention strategy.
- User identities must be **cloud-only**; accounts with `onPremisesSyncEnabled=true` block this project. Hybrid source identities are intentionally another project.
- Keep output in a protected folder: inventories contain employee names, emails, app configuration, security policy metadata and tenant IDs. `.gitignore` excludes `output/` and generated sensitive files.

## Single-entry PowerShell workflow (recommended)

**All operations run through `main.ps1` in the repository root.** It loads
`modules/Migration.Workflow.psm1`, which validates configuration and dispatches
to the existing `scripts/*.ps1` as dedicated helper commands. Each PowerShell
helper executes in its **own process** to avoid Graph/Exchange/CTIM token crossover.
The helper scripts remain standalone for troubleshooting, but operators do not
need to call them directly.

```powershell
# One-time prerequisite installation (interactive, CurrentUser; install only needed modules).
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Beta.Migrations -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module MicrosoftTeams -Scope CurrentUser
# Install SPO and CTIM modules following Microsoft's supported OS/runtime guidance.

Copy-Item ./config/sample.json ./config/local.json
# Edit sourceTenantId, targetTenantId, staging domain, SharePoint admin URLs and DNS.

# Interactive stage menu (all stages accessible from the same console entry point):
pwsh ./main.ps1

# Automation-friendly CLI, also using ONLY main.ps1:
pwsh ./main.ps1 -Stage Plan
pwsh ./main.ps1 -Stage Prerequisites
pwsh ./main.ps1 -Stage AllReadOnly -IncludeServices
pwsh ./main.ps1 -Stage InventorySource
pwsh ./main.ps1 -Stage IdentityMap
pwsh ./main.ps1 -Stage Assess
pwsh ./main.ps1 -Stage DnsAudit
pwsh ./main.ps1 -Stage TargetUsers               # DRY RUN; does not create accounts
pwsh ./main.ps1 -Stage MailboxReadiness
pwsh ./main.ps1 -Stage MigrationPreview -CutoverUtc '2026-12-15T02:00:00Z'
```

`AllReadOnly` runs Graph inventory for **both** tenants, optionally Exchange,
Teams and SharePoint inventory in both with `-IncludeServices`, then builds the
initial identity map, assesses and checks DNS. It never mutates either tenant.
Service discovery requires applicable modules and authenticates independently;
if SharePoint is in scope, provide source/target admin URLs in `config/local.json`
or use `-SourceSPOAdminUrl` / `-TargetSPOAdminUrl`. To intentionally skip that
one workload, supply `-SkipSharePoint`; omissions are not a completed inventory.

### Approved migration stages from main.ps1

The interactive menu asks for **exact** approval phrases; for noninteractive jobs,
pass `-Execute` and the required phrase. No stage creates users, writes CTIM,
or initiates migration simply by being selected.

```powershell
# Approve the reviewed output/identity-map.csv first (approved=true on each row).
# Target users are created UNLICENSED, with sign-in disabled.
pwsh ./main.ps1 -Stage TargetUsers -Execute -ApprovalPhrase 'CREATE-MAILUSERS:<TARGET-TENANT-GUID>'

# Microsoft CTIM — each phase isolates its tenant session.
# SourceCopy requires -TenantRole Source and -SourceScopeSecurityGroupId.
pwsh ./main.ps1 -Stage Ctim -CtimPhase SourceCopy -TenantRole Source -SourceScopeSecurityGroupId '<SOURCE-SCOPE-SECURITY-GROUP-GUID>'
# For execution add -Execute -ApprovalPhrase 'CTIM:<SOURCE-TENANT-GUID>:SourceCopy'
# Target phases: TargetAccept (with -RequestId), TargetMap, TargetWrite, TargetReport.

# After CTIM, target MailUser and OneDrive absence verification, licensing,
# customer approvals and workload-specific manual gates:
pwsh ./main.ps1 -Stage MigrationCreate -CutoverUtc '2026-12-15T02:00:00Z' -Execute -ApprovalPhrase 'APPROVED:<TARGET-TENANT-GUID>'
pwsh ./main.ps1 -Stage MigrationValidate -JobId '<JOB-ID>' -Execute -ApprovalPhrase 'APPROVED:<TARGET-TENANT-GUID>'
pwsh ./main.ps1 -Stage MigrationStatus -JobId '<JOB-ID>'
pwsh ./main.ps1 -Stage MigrationStart -JobId '<JOB-ID>' -Execute -ApprovalPhrase 'APPROVED:<TARGET-TENANT-GUID>'
```

All examples above are one-line PowerShell commands; copy each full line into the terminal.
The dispatcher refuses to overwrite an approved or target-mapped identity CSV during rediscovery.

**Important:** `main.ps1` is a **single interface, not a universal one-click
migration**. Unsupported native workloads (Teams channels, SharePoint in many
CSP tenants, Intune device enrollment, enterprise-app recreation, etc.) require
manual/vendor-specific runbooks and signoffs. No false `success` reporting.

### Workflow directory

```text
main.ps1                         # interactive menu + CLI; only operator entry
modules/Migration.Workflow.psm1  # config validation, ordered dispatch, guards
scripts/*.ps1                    # independent Graph/EXO/CTIM/Teams/SPO helpers
tools/*.py                       # offline readiness and cost analysis
config/local.json                # private tenant settings (gitignored)
output/                          # private inventory and reports (gitignored)
```


## Documentation

- [Requirements and security gates](docs/REQUIREMENTS.md)
- [CAD licensing and costs, dated 2026-10-29](docs/LICENSING-COSTS.md)
- [Workload coverage and limitations](docs/WORKLOAD-MATRIX.md)
- [DNS timing, coexistence and domain switch](docs/DNS-CUTOVER.md)
- [Professional phase-by-phase runbook](docs/RUNBOOK.md)
- [Migration risks and decision record](docs/RISKS-AND-GAPS.md)
- [Microsoft references](docs/SOURCES.md)
- [GitHub publishing steps](docs/PUBLISH-GITHUB.md)
- [Post-cutover QA](docs/POST-CUTOVER.md)
- [Architecture and migration dependency flow](docs/ARCHITECTURE.md)

## Tests and privacy

```bash
python -m unittest discover -s tests -v
python -m json.tool config/sample.json > /dev/null
```

PowerShell live integration tests **not run in this environment** (PowerShell unavailable here). Use an isolated pilot tenant, Pester, and approval from a customer admin before executing any migration-affecting commands. Never publish real migration inventory. Sample fixtures are fabricated.

## GitHub repository

Source: https://github.com/federico8a/-m365-cloud-tenant-migration . This repository is an **engineering starter**, not a production-certified tenant migration. Follow the approval gates, perform pilot testing, and use vendor-supported workflows for unsupported workloads.

## Estimated cost calculation

```bash
python tools/cost_model.py --users 150 --license 'Business Premium' --overlap-months 2 --sharepoint-gb 450
```

The result deliberately **does not** invent a CAD price for CTUDM or native SharePoint licensing: enter a confirmed CAD CTUDM quote via `--ctudm-quoted-cad-per-user`. Native SharePoint is EA-eligible only as documented. The estimate also excludes remaining source subscriptions/annual commitments and third-party services.

## Dedicated cloud-only migration control points

- `scripts/New-CloudTargetUsers.ps1` uses Microsoft's supported **Exchange Online New-MailUser** method, not plain Graph user creation, so CTIM can stamp the required Exchange attributes. It creates **unlicensed MailUsers with disabled sign-in** and no retained passwords. Manual user onboarding (password reset/TAP) still required at cutover.
- `scripts/Invoke-Ctim.ps1` provides step-by-step staged native CTIM commands with separate source and target identities; follow official tenant-relationship and scope-group preparation first. CTIM is **not replaced** by the CSV proposal.
- `scripts/Test-TargetMailboxReadiness.ps1` reports missing MailUsers and preexisting destination mailboxes; this is **Exchange-only** and does not prove OneDrive readiness.
- `main.ps1` is the sole recommended operator entry point: interactive menu or `-Stage`, calling workflow modules and isolated helper scripts; approval gates and the customer change plan remain mandatory.
