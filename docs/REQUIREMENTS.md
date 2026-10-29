# Engineering requirements and acceptance criteria

**Scope:** 2026-10-29 cloud-only commercial M365 Tenant A -> Tenant B. Tenant B may be a pre-existing tenant. On-premises AD, Entra Connect, Exchange hybrid and on-premises connectors are explicitly OUT OF SCOPE; separate hybrid migration project.

## 1. Customer authorization and design decisions (HARD GATES)

1. Written customer ownership proof for each tenant; permission to access Microsoft Graph, Exchange, SharePoint and Intune data; approval of tenant-specific admin consent. Confirm target tenant and region/cloud boundary.
2. Confirm merger/consolidation vs divestiture; whether all data can transfer, retention/discovery requirements, data residency, legal/union/privacy restrictions, encryption/Customer Key requirements, acceptable outage and coexistence window.
3. Record source/target tenant IDs; namespace (custom domain to move vs retained at source); tenant geo, exchange organization, available vanity subdomains, tenant SPO hostnames; CSP/EA/Web Direct agreement types and contracts.
4. Identify migration batch owner, change manager, security owner, compliance/legal owner, DNS registrar owner, business process owners, vendor contacts and support escalation.
5. Distinguish data move from configuration rebuild, authentication/session recreation, licenses/subscriptions and device re-enrollment. A true 100% transparent move is NOT supported across all Microsoft 365 services.

## 2. Discovery (read-only)

- Entra: user IDs (immutable GUIDs), UPN, mail, aliases, userType, directory sync flag, groups (static/dynamic/M365), memberships/owners, directory role assignments, guests, domains, named locations, CA, authentication policies, PIM, identity governance, custom security attributes, admin units, app registrations, service principals, app consents, federated credentials, permissions, authentication flows, API/webhook owners, enterprise app SAML/OIDC/SCIM integrations, external identities.
- Exchange: user/shared/resource/room/equipment mailboxes, size, archives, holds, retention, mailbox permissions, calendars/delegates, forwarding, accepted/remote domains, mail flow connectors, transport rules, journaling, mail contacts/groups, public folders, address books, eDiscovery, mail-enabled security, DKIM, DMARC.
- OneDrive: quota, file count/path limits, sync/shortcuts, sharing, external permissions, holds, Customer Key, target pre-existing sites.
- SharePoint: modern/classic/group-connected/communication sites, item counts/storage, site collections, hub structure, permissions, retention, labels, apps, custom webparts, workflows, links, taxonomy, content types, lists, SPFx, Power Platform references; no target site collisions.
- Teams: personal chats, meetings, Teams/channel structure, shared/private channels, tabs/apps/bots, meetings/calendar/recordings/transcripts, live events, webinar/town hall, phone numbers/PSTN, policies, Rooms, third-party app dependencies.
- Intune/Windows: enrolled devices, join state, enrollment restrictions, Windows Autopilot hardware IDs, configuration/compliance profiles, security baselines, settings catalog, ASR, Defender, device filters, Win32/mobile apps, certificates, SCEP/PKCS, Wi-Fi/VPN, DLP, scripts/remediations, Apple ADE/ABM, Android Enterprise, Windows 365, macOS, mobile enrollment, WUfB.
- Security and governance: Defender for Office 365/Endpoint/Cloud Apps/Identity, Defender XDR/Sentinel connectors (Azure separate), Purview audit, retention, DLP, sensitivity, auto-label, Insider Risk, Communication Compliance, eDiscovery cases/holds, Customer Key, records management, M365 Backup.
- Business workloads: Power Platform environments, solutions, flows, custom connectors, gateways, Dataverse, Dynamics 365, Copilot Studio, Power Pages, Planner basic/premium, Forms, Lists, Loop, Whiteboard, Bookings, Viva Engage, Viva Connections/Insights/Learning, Stream, OneNote, Sway, To Do, Project, Visio, Power BI/Fabric, Copilot agents, Search connectors and metadata, Teams apps.
- Licensing and subscriptions: SKUs, service plans, available/consumed seats, add-ons, annual/renewal term, NCE cancellation restrictions, CSP relationship, prepaid vs pay-as-you-go capacity, telephony carrier agreements.

`Export-GraphInventory.ps1` covers an important subset; the matrix marks deep inventories that require additional service-specific APIs or manual methods. Do not interpret a successful Graph collection as proof the entire workload was assessed.

## 3. Network, identity and security prerequisites

- Use verified staging domain in target; DO NOT release source production domain during discovery.
- Configure mail flow coexistence, Exchange organization relationships, source scope group, target endpoint/migration application permissions, CTIM identity mapping; pilot mail and calendar tests.
- Create target MailUsers according to Microsoft instructions; **run identity mapping BEFORE assigning destination Exchange/Teams licenses**; ensure no Exchange mailbox provisioned and disable automatic OneDrive creation. Never precreate target OneDrive or SharePoint site for native site move.
- Migration access via named accounts, dedicated scoped roles, privileged access/approval, audit evidence, rotate app secrets, never copy credentials. Security settings and MFA registrations must be rebuilt or re-enrolled; don't promise password hashes, token sessions or FIDO2 keys transfer.
- Prepare private delegated admin/Graph consent with minimum necessary permissions. Avoid blanket Global Administrator where a specific M365 Migration Administrator/Exchange/SharePoint/Intune role suffices.
- Confirm holds and legal approvals; hold removal is never automatic. Pilot and validate each workload before committing to broader migration.

## 4. Workload deployment / acceptance

- Identity: every in-scope source user maps to one target Entra object ID (not an on-premises SID); collisions resolved; guests and apps assessed separately; access tests pass.
- Exchange: all eligible mailboxes migrated, mail-flow and free/busy tested, shared/room permissions verified, NDRs/legacy X500 addressed, unmovable holds explicitly escalated.
- OneDrive/SharePoint: site/file counts, versions, metadata and delegated permissions validated; URL, redirects/links, external sharing, labels, embedded references tested against agreed samples.
- Teams: migrated supported chat/meeting results explicitly reported with any skipped/failed messages; **Teams workspaces/channels** independently accounted for.
- Devices: per-platform re-enrollment procedures and endpoint security validation; no silent loss of management or BitLocker key access.
- Applications: user/role assignment remapping, vendor re-consent, OAuth redirect/issuer updates, webhook testing, new secrets/certificates (never exported private keys), credential rotation, and SAML certificate/metadata handoff.
- Security: policies recreated/remapped, least privilege validated, approved differences documented; historic audit/security telemetry may not transfer.
- DNS: MX/Autodiscover/SPF/DKIM/DMARC and third-party relay verified after domain handoff; plan DNS rollback without implying moved mailbox data can simply move back.
- Customer: change approval, migration results, agreed exception log, hypercare runbook and source-retirement authorization.

## 5. Operational safety

- No destructive source user/app/site deletion in this toolkit.
- Read-only discovery by default; `Invoke-NativeOrchestrator.ps1` can mutate only with `-Execute` and a tenant-specific approval phrase.
- Separate service owner approvals for licensing purchase, mailbox/OneDrive move, domain release, device wipes, holds and data deletion.
- Do not automatically copy production JSON directly into POST/PUT calls: values include immutable IDs, generated resources, secrets/certificates and tenant-specific references.
- Stage synthetic test data, review sample migration batches, verify Pester/unit tests and dry runs, maintain exception and retry evidence.
