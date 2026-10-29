# Migration execution runbook — cloud-only Microsoft 365 A -> B

**Status: engineering pilot toolkit, NOT a claim of unattended end-to-end migration of all M365 services.** Owner and security approval mandatory for each mutating wave. Follow the supported Microsoft-native runbooks linked in [SOURCES](SOURCES.md). Estimated downtime is **not guaranteed**: actual impact depends on tenant topology, amount of content, throttling, domain release, DNS TTL, endpoint states and user sign-in.

## Phase 0 — Customer authorization (T-4 weeks or earlier)

- Signed change order with source tenant, target tenant, authorized owners, destination region, services and data transfer legal basis. Identify any merger, split and third parties. Confirm source data can be disclosed to target.
- Migrate **cloud-only** user accounts exclusively. Any `onPremisesSyncEnabled=true` is a stop; hybrid migration is separate. Require proof administrative control of both tenants, emergency cloud-only admin accounts in *both* and a secured break-glass strategy.
- Record customer RTO/RPO, wave size, target state, coexistence, maintenance windows (time zones!), business blackout dates, licensing commitments, communications and roll-back/compensating-actions decision points.
- Enumerate all objects (see WORKLOAD-MATRIX), not just licensed users; guests, shared/room/equipment mailboxes, resources, archival, holds, multi-geo, customer key, 3P SaaS SSO, B2B, data owners, managed devices and phones.
- Separate security and privacy signoffs for API application permissions, endpoint re-enrollment, removing a custom domain, number porting, inactive mailbox/hold handling, source tenant retirement and backup disposal.

## Phase 1 — Inventory and costed architecture (T-3 weeks)

```powershell
# Local interactive admin authentication: run once per tenant, never concatenate data from two tenants without labels.
./scripts/Export-GraphInventory.ps1 -TenantId '<SOURCE-TENANT-GUID>' -OutputDirectory './output/source'
./scripts/Export-GraphInventory.ps1 -TenantId '<TARGET-TENANT-GUID>' -OutputDirectory './output/target'
./scripts/Export-ServiceInventory.ps1 -TenantId '<SOURCE-TENANT-GUID>' -SPOAdminUrl 'https://SOURCE-admin.sharepoint.com' -OutputDirectory './output/source'
./scripts/Test-DnsReadiness.ps1 -Domain 'example.com' -OutputPath './output/dns-before.json'
```

- Run inventory under delegated least privilege. Review `collection-errors.json` for permission/scoping failures. Treat 403 and missing data as incomplete, not absent.
- Determine actual licensed services and Partner Center/EA/CSP eligibility. Quote cross-tenant user migration add-on, per-100 GB shared data EA-only license if eligible, and service-specific third-party migration tools.
- Verify migration API cloud support and rollout status in tenant. Microsoft Graph migration orchestration is **beta** and not supported for production apps according to the Graph API warning; a live pilot requires customer/Microsoft approval.
- Decide native (Exchange/ODSP/personal Teams), native SharePoint for EA eligible customers, qualified third party for otherwise unsupported Teams/SharePoint/workloads, or rebuild. Sign off on excluded data.

## Phase 2 — Destination foundation, accounts and licenses (T-2 weeks)

1. Build Tenant B security baseline: MFA/CA staged in report-only, Emergency Access identities, audit/retention, domains, device enrollment, external collaboration and sign-in policy. Avoid locking out operators.
2. Prepare a `*.onmicrosoft.com` or separate staging domain. **Never pre-verify a custom domain still attached to Tenant A**, and do not cut over MX now.
3. Generate a candidate mapping and verify UPN collisions, aliases and IDs:

```powershell
./scripts/New-IdentityMap.ps1 -SourceUsers './output/source/users.json' -SourceMailboxes './output/source/mailboxes.json' -TargetStagingDomain 'TARGET.onmicrosoft.com' -OutputPath './output/identity-map.csv'
```

4. Have customer approve source/target mapping and provision **unlicensed, disabled** destination cloud identities using `New-CloudTargetUsers.ps1` (if creating target users is appropriate). New Entra object IDs are unavoidable. New passwords/keys/MFA registrations cannot be copied from A; deliver onboarding through approved authentication recovery/TAP flows.
5. **Native mailbox/OneDrive migration ordering is critical:** target users must have NO mailbox, NO OneDrive site. Create correct MailUser routing and migration endpoint/organization relationships/scope security group according to Microsoft. Run Microsoft's **CrossTenantIdentityMapping (CTIM)** supported module in both tenants **before adding any Exchange-producing workload license**. CTIM stamps source ExchangeGUID/ArchiveGUID/x500 etc. Validate via Exchange Online PowerShell. The local identity-map.csv is an *approval manifest*, **not a substitute for CTIM**.
6. Disable target OneDrive creation before assigning workload licenses. Confirm source/target Teams and Exchange service licenses and per-user CTUDM. Licensing an unprepared account can provision an incompatible target mailbox or OneDrive, causing native migration to fail.
7. Source-side legal holds/retention conflicts must go through counsel; do **not** remove a hold merely to pass migration validation. Document exceptional dispositions.
8. Activate temporary access, target policies and passwords **only when user cutover plan requires it**; review app registrations, enterprise app SSO callbacks, CA policy scope and SCIM dependencies.

## Phase 3 — Pilot and prevalidation (T-10 days)

- Pilot 3–5 fictitious/noncritical users across normal mailbox, archive, sharing, one complex Teams chat, OneDrive, a group-connected SharePoint site and a managed device; expand pilots after success.
- Run `python ./tools/assess.py ...` to check mapping and inventory; resolve *all* blockers. Its `HUMAN_GATES_REQUIRED` status means a human must complete additional checks, **not** `GO`.
- Native Graph Migration Orchestrator job (Tenant B): `Preview` only, inspect JSON, obtain change approvals. `Create` triggers validation, `Validate` retries on `ValidateFailed`, `Migrate` submits cutover/processing. Sample commands in README. Workloads `Exchange`, `ODSP`, `Teams` and `Meeting` only; it does **not** move Teams channel workspaces or SharePoint sites.
- Microsoft recommends staging jobs roughly **two weeks** ahead of planned complete-after date to allow Exchange pre-sync. The complete-after time is the *earliest permitted* cutover, **not** a promise of exact completion.
- Check validation at **batch and per-user workload level**; prerequisite validation expires after 7 days.
- Microsoft Teams successful user status can still include some skipped messages; inspect message and thread counts, not status alone.
- For SharePoint native EA: validate site size/item count, target site nonexistence, Customer Key, mappings, licenses and unsupported site assets. Since native cross-tenant is **one move, no delta**, schedule a content freeze and communications. For non-EA, contract capable third-party provider with evidence test.

## Phase 4 — Cutover (T-0)

- Final backups/export evidence (where legally and technically supported), signed GO decision, incident bridge, freeze changes and service-specific cutover steps. Record UTC timestamps and reversible/irreversible boundaries.
- Execute migration jobs only after per-workload approvals. Check submitted vs actual cutover progress; do not call a submitted job successful.
- Perform DNS/domain transfer only **after** the source domain can safely be removed and service address changes are coordinated. See [DNS-CUTOVER.md](DNS-CUTOVER.md). MX alone is not a full tenant move.
- Rebuild user sign-in and app SSO (app IDs/certs/secrets, redirects, consent, SAML/SCIM, credentials), UPN, Exchange address policies, transport rules/accepted domains, delegations and client profiles.
- For Intune, stage policies and app deployments but treat device unenrollment/re-enrollment, Autopilot, BitLocker key escrow, certificates, ADE/ABM/Android Enterprise tokens and endpoint Defender re-onboarding as distinct pilot-controlled steps.
- Teams Phone PSTN number porting and caller routing require carrier lead times and a separate explicit approval.

## Phase 5 — Verification and handover (T+0 to T+14)

- Compare source/target inventory (counts alone do not prove parity). Test sign-in/MFA/CA, licensing, mail routing both directions, delegate/archives, OneDrive files+sharing+versions, SharePoint ACL/version checks, Teams meetings/chats/channels, device compliance, DLP/retention, external apps, Power Platform, phone and report refresh.
- Record evidence: synthetic test messages + trace, `Get-MgContext`, target MailUser/mailbox GUID evidence, OneDrive/SharePoint item samples, Teams per-user migration results and known skips, policy comparison, DNS queries, alerts and exceptions. Do not store sensitive evidence in GitHub.
- Source tenant cannot just be deleted: native successful mailbox and ODSP moves change the source and leave redirects; keep licensed source workloads, legal evidence and data access as required by retention and contract. Produce offboarding gate signed by security/legal/customer.
- **Rollback is workload-specific**. Pre-cutover DNS routing reversal is often possible, but it is not reversal of a native one-time moved mailbox/OneDrive/SharePoint site. Document forward-recovery and restorations rather than advertising full rollback.

## Exit criteria

- 100% in-scope identities matched 1:1 with approved new object IDs; zero source synced users; tenant IDs verified.
- 100% licensed users have target SKU assignment plan; migration licenses purchased and service-specific assignment verified.
- All critical business workflows validated; unresolved unsupported items are acknowledged by the owner.
- Cutover and hypercare communications sent, risk register closed or accepted, financial closeout and data-retention approval signed.

See [SOURCES.md](SOURCES.md) for authoritative Microsoft documentation.
