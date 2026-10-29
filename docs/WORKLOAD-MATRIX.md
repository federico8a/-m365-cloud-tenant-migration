# Full Microsoft 365 workload coverage and support matrix

**Legend:** `Native` = vendor-supported specific Microsoft workload move; `Rebuild` = documented re-provision/rebind via Graph/PowerShell/admin UI; `3P` = third-party evaluation recommended where native is not feature-complete; `Gate` = licensing/legal/technical prerequisite. An exported JSON file is **not** equivalent to migrating service state, history, or secrets.

| Workload / often-missed objects | Preferred route | Exact caution / blocker |
|---|---|---|
| Entra cloud users / GUIDs / aliases | Graph inventory + approved MailUser creation/mapping | New object IDs; cannot move authentication credential hashes, passkeys, MFA registrations/session tokens; **hybrid excluded** |
| Entra groups: security/M365/dynamic | Graph inventory + approved reconstruction | New group IDs; dynamic rules/members/owners need mapping; M365 Groups connected to SharePoint/Teams need sequencing |
| Entra B2B guests / cross-tenant access | Invitation/reconfiguration | External identity consent and sponsors; don't clone guests blindly |
| Entra CA / named locations / auth methods / PIM / roles | Graph policy rebuild | Object references, tenant-dependent roles and license must be remapped; stage CA in report-only |
| Entra app registrations | Graph export + app redevelopment/re-registration | New appId, service principal; rotating secrets/certs; redirect URI, publisher, consent, API scopes/roles, federated creds |
| Enterprise apps / SAML / SCIM | Recreate/re-consent and vendor update | Recreate SSO certs, claims, SCIM provisioning, owners, assignment and API permissions; preserve app vendor cooperation |
| Exchange user mailboxes (mail, calendar, contacts, tasks, archives) | Native CTUDM + Graph orchestrator | Holds blocked; target MailUser and Exchange GUID must be prepared; migrated source mailbox deleted; content caveats |
| Shared/room/equipment mailboxes, delegates | Native where eligible; separately validate mailbox types | Shared mailbox CTUDM license exempt, but mail permissions/configuration require validation; room resource configuration |
| Exchange groups, dynamic distribution, contacts, public folders, journaling | Exchange PowerShell + specialized migration | Not guaranteed by user mailbox move; public folders need separate strategy |
| Exchange connectors/transport rules, DKIM/SPF/DMARC, external SMTP relays | Rebuild/change control | DNS and sender IP changes; third-party scanner/CRM integrations |
| OneDrive files, sharing and permissions | Native CTUDM | Site must NOT pre-exist at target, one-time/no delta; path/hold/Customer Key blockers |
| SharePoint sites, lists, document libraries and versions | EA-only native CTSMDM, else 3P | 5 TB/1M items, no pre-created site or delta; group-connected sites need special prep |
| SharePoint hubs, SPFx/apps, workflows, custom forms, links, taxonomy | Rebuild + content validation | Not automatically migrated by base site move; custom URL references and labels |
| Teams personal chats and supported meetings | Orchestrator CTUDM | Scoped support, skips/duplicate threads possible, per-user success thresholds; beta Graph API |
| Teams, channels, private/shared channels, memberships, tabs, apps/bots | 3P or rebuilt structure + content | Native Orchestrator specifically excludes Teams/channel workspace migration; Graph channel import API is NOT generic transfer of whole Teams |
| Teams meeting recordings/transcripts | OneDrive/SharePoint + separate validation | Links and owner permissions may change; webinars/town halls assessed separately |
| Teams Phone, Auto Attendants, Call Queues, resource accounts, Direct Routing | Voice migration plan + provider porting | Teams Phone SKU/carrier/SBC/PSTN numbers; avoid porting before test |
| Teams Rooms/Teams devices | Reenroll/reconfigure | Room licenses, calendar accounts, certificates |
| Intune configuration/compliance/endpoint security profiles | Graph export + tenant-specific rebuild | Partial API support; assignments, settings catalog, security baselines, app IDs, scripts and certificates |
| Intune enrolled devices (Windows/macOS/iOS/Android) | Controlled unenroll and re-enroll | No tenant ownership transfer; user impact, key escrow, conditional access interruption |
| Windows Autopilot / Windows 365 / Apple ADE / Android Enterprise | Individual device/platform runbooks | Hardware association/ownership, images, reprovisioning, enrollment restrictions, Apple/Google token changes |
| Defender for Office 365/Endpoint/Cloud Apps/XDR | Policy redeploy + endpoint re-onboarding | Security alerts/history generally not portable; sensor integrations and Defender platform entitlements |
| Purview: DLP, sensitivity, retention, eDiscovery/holds, records | Rebuild after legal review | No generic compliant export/import of all history; DO NOT remove holds to force migration |
| M365 Backup, audit logs, reports, alerting | New backup and archival plan | Backup/restore boundaries; regulatory evidence preservation |
| Power Apps/Automate/Dataverse/Dynamics 365 | Native supported environment move, solutions/flows + mapping | Production/sandbox Dataverse only, not default/developer/trial/Teams; relink connectors, gateways, endpoints |
| Copilot Studio, Power Pages, Power Platform gateways | Solution migration, reprovision and validation | Agents/data sources, website bindings, flow URLs and credentials need reconfiguration |
| Power BI/Fabric capacity, workspaces, semantic models, gateways, reports | Recreate/deploy where supported | Refresh/data credentials, access/licensing and capacity SKU; Git definitions do not move underlying data |
| Planner basic/premium / Project / To Do | Specialized supported methods or 3P | Plan IDs, task assignments, comments/attachments/links; premium Project data may require Dataverse |
| Microsoft Forms / Lists / Bookings / Whiteboard / Loop / OneNote | Per-service documented rebuild/move / 3P evaluation | Ownership, submission history, embedded links, workspaces and ACLs may not transfer |
| Stream (on SharePoint), Viva Engage/Learning/Connections/Insights | File migration + service rebuild | Communities, videos, targeting, provider data and links |
| Microsoft Search/Graph Connectors/agents/Copilot | Re-register connectors and rebuild grounding | Graph index, agent publishing, tenant data boundaries and license |
| Microsoft 365 Groups guest sharing / external tenant partnerships | Graph & admin centre rebuild | Access policies and domain allow/deny lists need reapproval |
| Billing/CSP/NCE/EA and subscriptions | Commercial reconciliation | User data migration does NOT transfer license ownership/billing contract |
| Azure subscriptions/VMs/VNets/AKS/Arc/on-prem connectors | **Separate Azure/hybrid project** | Not in cloud-only M365 scope; tenant transfer is distinct from M365 data migration |

## Third-party tool evaluation (not blanket promises)

- **Quest On Demand Migration**: strong candidate for complex cross-tenant Teams and Microsoft 365 Groups projects; review each workload entitlement and limitations with sales. https://www.quest.com/products/on-demand-migration/
- **ShareGate Migrate**: strong candidate for SharePoint and Teams/Planner content in the supported versions; verify chat and app coverage. https://sharegate.com/
- **AvePoint Fly**: evaluate broader Microsoft 365 migration, Teams, Exchange, OneDrive and SharePoint content against actual SKU and API restrictions. https://www.avepoint.com/products/fly
- **BitTitan MigrationWiz**: evaluate Exchange mailbox and OneDrive/SharePoint scenarios and purchased project types; do not assume it covers all Intune/Entra/security workloads. https://www.bittitan.com/migrationwiz/

**Vendor due diligence:** Request a feature-level POC and written scope: Teams chats vs channels, Planner, page versions, private/shared channel files, permissions, item versions, audit evidence, throttling, geo restrictions, re-runs/deltas, application settings, and support. Python is appropriate for reporting, mapping, transformation, and verification; it does not bypass Microsoft Graph's unsupported migration capabilities.
