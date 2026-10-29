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

## Terminal quick start

```powershell
# 1. Install only what you need. Never check credentials/secrets into Git.
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Beta.Migrations -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module MicrosoftTeams -Scope CurrentUser

# 2. Duplicate and edit configuration; use real GUIDs for source and target.
Copy-Item config/sample.json config/local.json

# 3. Source tenant: read-only Graph discovery. Sign-in is interactive.
./scripts/Export-GraphInventory.ps1 -TenantId '<SOURCE-GUID>' -OutputDirectory './output/source'

# 4. Target tenant: read-only discovery; NEVER auto-license/mailbox users.
./scripts/Export-GraphInventory.ps1 -TenantId '<TARGET-GUID>' -OutputDirectory './output/target'

# 5. Optional service inventory (run per tenant; use correct admin URLs).
./scripts/Export-ServiceInventory.ps1 -TenantId '<SOURCE-GUID>' -SPOAdminUrl 'https://source-admin.sharepoint.com' -OutputDirectory './output/source'

# 6. Generate map for HUMAN REVIEW. Ensure unique verified target identities.
./scripts/New-IdentityMap.ps1 -SourceUsers './output/source/users.json' -SourceMailboxes './output/source/mailboxes.json' -TargetStagingDomain 'target.onmicrosoft.com' -OutputPath './output/identity-map.csv'

# 7. Optional: preview creating cloud-only target MailUsers with source routing.
./scripts/New-CloudTargetUsers.ps1 -TargetTenantId '<TARGET-GUID>' -TargetOrganization 'target.onmicrosoft.com' -MappingCsv './output/identity-map.csv' -TargetStagingDomain 'target.onmicrosoft.com' -OutputCsv './output/identity-map-target.csv'
#    See docs/RUNBOOK.md and scripts/Invoke-Ctim.ps1 for staged, approved execution.

# 8. Offline assessment; EXPLICIT FAIL on synced users, conflicts, missing targets.
python ./tools/assess.py --source ./output/source --target ./output/target --mapping ./output/identity-map.csv --output ./output/readiness.json

# 9. After following prerequisites in docs/RUNBOOK.md and obtaining approvals,
#    prepare a DRY-RUN batch payload (NO API mutation).
./scripts/Invoke-NativeOrchestrator.ps1 -Action Preview -ConfigPath './config/local.json' -MappingCsv './output/identity-map.csv' -CutoverUtc '2026-12-15T02:00:00Z'

# 10. Create/validate/migrate batch only under approved change control.
#    See docs/RUNBOOK.md; not executed without explicit confirmation.
```

**Critically important sequence:** Create target MailUsers -> configure target/source tenant relationship + migration endpoint -> complete Microsoft's cross-tenant identity mapping (stamps Exchange GUID) -> check absence of destination mailbox and OneDrive -> assign appropriate destination workloads & migration SKU -> create migration batch -> validate -> schedule and execute cutover. Source domain/DNS is NOT switched when you start pre-migration discovery. See `docs/DNS-CUTOVER.md`.

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
- `scripts/Invoke-M365Migration.ps1` offers a single terminal entry point for discovery, identity map generation, assessment, DNS audit and orchestrator preview; the multi-step approved migrations must still follow the customer change plan and module-specific commands.
