# Architecture and execution flow

**Scoping:** Commercial Microsoft 365 cloud-only tenants A and B, not on-prem AD / Exchange hybrid, not Azure subscription migration.

```mermaid
flowchart TD
    A[Customer change and security approvals] --> B[Inventory Tenant A and Tenant B]
    B --> C[CSV user ID mapping and blockers]
    C --> D[Target staged MailUsers no licenses]
    D --> E[EXO relationships and scoped migration endpoint]
    E --> F[Native CTIM identity mapping and GUID stamping]
    F --> G[Confirm no target mailbox or OneDrive site]
    G --> H[Verify workload licenses and CTUDM]
    H --> I[Orchestrator Exchange, OneDrive, chats, meetings]
    I --> J{Validation passed and approval?}
    J -->|No| K[Fix errors, resubmit validation]
    K --> J
    J -->|Yes| L[Approved wave migration]
    L --> M[Controlled production DNS and custom domain cutover]
    M --> N[Acceptance, hypercare, retention and handover]
    B --> O[SharePoint site inventory]
    O --> P{Native EA CTSMDM eligible?}
    P -->|Yes| Q[Native separate SharePoint one-time move]
    P -->|No| R[Third party or documented rebuild]
    B --> S[Teams channels, Intune, Entra apps, Purview, Defender, Power Platform, Fabric]
    S --> T[Supported rebuild, native environment move, or third party POC]
    Q --> N
    R --> N
    T --> N
```

**No magical universal transaction:** The arrows are dependency order, not proof every workload migrates. A native OneDrive, mailbox or SharePoint move can be one-way; source deletion, redirect preservation and service-level evidence must be managed explicitly. Graph beta orchestrator exposes user workload migration, not a complete all-service move.

## Ownership and privileges

| Actor | Access | Gate |
|---|---|---|
| Customer sponsor/change manager | Approved scope and maintenance | Signed business authorization |
| Source tenant Entra + EXO admins | Inventory, scoped org relationship, CTIM source copy | Source tenant ID and role verified |
| Target tenant Migration Admin/EXO/SharePoint admins | Target foundation, CTIM accept/write, orchestration | Target tenant ID, least privilege, module version pinned |
| Compliance/legal owner | Holds, Purview, retention, evidence | No automatic hold removal or deletion |
| DNS owner | Domain zone export, TTL, production record changes | Domain release and external mail-flow GO |
| Endpoint owner | Intune re-enrollment, encryption recovery and policy tests | Pilot devices + user coordination |
| Application owners | Enterprise apps, SSO/SCIM/OAuth, agents, flows | Vendor collaboration and sign-in tests |
| Finance/CSP partner | SKU / EA eligibility / purchased add-ons | Verified purchase and budget approval |

## Key design choices

1. Use delegated Graph sessions for read-only inventory; handle partial API failures as blockers.
2. Externalize configuration; keep all customer exports in `output/`, never in Git.
3. Use **Entra object GUIDs**, not AD SIDs or mutable UPN alone, for native migration identity mapping; new target IDs are mandatory.
4. Do not store plaintext/hashed source passwords: users reset or receive controlled temporary access after cutover.
5. Use Microsoft's CTIM module for GUID/X500 stamping rather than a hand-written Graph PATCH that risks unsupported Exchange attributes.
6. Separate read-only inventory, pilot/validation, production execution, DNS and irreversible customer actions. No automated 'run everything' command can safely perform these without approvals.
