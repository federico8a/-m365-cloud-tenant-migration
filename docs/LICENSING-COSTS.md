# Licensing & costs — Canada (CAD) — researched October 29, 2026

**Pricing caveat:** Public Microsoft Canada pages below show commercial web prices, generally **user/month with annual commitment**, before tax and excluding negotiated CSP/EA discounts. Pricing, standalone vs bundled service plans, Teams variants and July 2026 package changes MUST be rechecked against the customer's actual invoice/Partner Center quote on project start. A license is required only where features are needed; **do not add separately priced components that are already included** in a suite.

## 1. Destination base packages (public CAD)

| License | CAD/user/month | Included/usage | Public source |
|---|---:|---|---|
| Microsoft 365 Business Basic | 9.50 | Exchange, OneDrive, Teams where Teams-inclusive offer selected; up to 300 seats | [MS business](https://www.microsoft.com/en-ca/microsoft-365/business/compare-all-microsoft-365-business-products-b) |
| Microsoft 365 Business Standard (with Teams) | 19.00 | Basic plus desktop apps; up to 300 seats | [MS Standard](https://www.microsoft.com/en-ca/microsoft-365/business/microsoft-365-business-standard) |
| Microsoft 365 Business Premium (with Teams) | 29.80 | Recommended SMB endpoint/security baseline; up to 300 seats | [MS Premium](https://www.microsoft.com/en-ca/microsoft-365/business/microsoft-365-business-premium) |
| Microsoft 365 E3 | 52.90 | Enterprise productivity/security/management | [MS Enterprise](https://www.microsoft.com/en-ca/microsoft-365/enterprise/microsoft-365-plans-and-pricing) |
| Microsoft 365 E5 | 81.40 | Advanced enterprise security/compliance | [MS Enterprise](https://www.microsoft.com/en-ca/microsoft-365/enterprise/microsoft-365-plans-and-pricing) |
| Office 365 E3 | 35.30 | Office 365 workloads; does not equal M365 E3 security entitlement | [MS Office](https://www.microsoft.com/en-ca/microsoft-365/enterprise/office-365-plans-and-pricing) |
| Office 365 E5 | 55.60 | Expanded Office 365 capabilities; distinct from M365 E5 | [MS Office](https://www.microsoft.com/en-ca/microsoft-365/enterprise/office-365-plans-and-pricing) |

| Microsoft 365 E7 | 134.30 | Advanced Copilot/agent management with enterprise suite features, only if customer requires | [MS Enterprise](https://www.microsoft.com/en-ca/microsoft-365/enterprise/microsoft-365-plans-and-pricing) |

**Teams/no-Teams SKUs:** explicitly determine which version the customer owns and migrate or purchase Teams entitlement accordingly. Microsoft 365 Business Premium *without* Teams is listed separately (CAD 25.50/month annual). Some enterprise plans have additional packaging choices.

## 2. Conditional feature licenses (only where needed)

| Feature/SKU | CAD/user/month unless noted | Usage/notes | Public source |
|---|---:|---|---|
| Entra ID P1 | 9.50 | CA; included in Business Premium/M365 E3/E5 | [Microsoft](https://www.microsoft.com/en-ca/security/business/microsoft-entra-pricing) |
| Entra ID P2 | 13.60 | Risk/Identity Protection; included in M365 E5 | [Microsoft](https://www.microsoft.com/en-ca/security/business/microsoft-entra-pricing) |
| Intune Plan 1 | 10.90 | Included in Business Premium/M365 E3/E5 | [Microsoft](https://www.microsoft.com/en-ca/security/business/microsoft-intune-pricing) |
| Intune Plan 2 | 5.40 | Only if feature NOT already bundled (2026 M365 E3 changes) | [Microsoft](https://www.microsoft.com/en-ca/security/business/microsoft-intune-pricing) |
| Intune Suite | 13.60 | Advanced add-on to Plan 1, verify 2026 inclusions | [Microsoft](https://www.microsoft.com/en-ca/security/business/microsoft-intune-pricing) |
| Teams Phone Standard | 13.60 | Separate Teams entitlement and PSTN carrier/calling plan may be required | [Microsoft](https://www.microsoft.com/en-ca/microsoft-365/business/with-teams-plans-and-pricing) |
| Teams Phone domestic calling (Canada/UK) | 23.10 | Teams required; plan includes Teams Phone | [Microsoft](https://www.microsoft.com/en-ca/microsoft-teams/microsoft-teams-phone) |
| Power Apps Premium | 27.10 | Premium connectors/Dataverse business apps | [Microsoft](https://www.microsoft.com/en-ca/power-platform/products/power-apps/pricing) |
| Power Automate Premium | 20.40 | Premium flows/connectors; Basic included with select M365 subscriptions | [Microsoft](https://www.microsoft.com/en-ca/power-platform/products/power-automate/pricing) |
| Power BI Pro | 19.00 | Publishing and sharing; assess existing suite entitlements | [Microsoft](https://www.microsoft.com/en-ca/power-platform/products/power-bi/) |
| Power BI Premium Per User | 32.60 | Dedicated advanced BI use rights | [Microsoft](https://www.microsoft.com/en-ca/power-platform/products/power-bi/) |

For Microsoft Purview, Defender advanced plans, Fabric capacity, Dynamics 365, Copilot, Windows 365, M365 Backup, M365 Multi-Geo and telephone number porting, **price is scenario-specific**: get the precise SKU/region/capacity and official quote. Do not invent a flat tenant-wide migration fee.

## 3. Native cross-tenant migration purchase requirements

### Cross Tenant User Data Migration (CTUDM)

- **Required** for Microsoft's native Exchange/OneDrive and Migration Orchestrator supported user workload moves.
- Single-use per user; Microsoft's licensing FAQ says expires after one use or one year from purchase. One license applies to the user mailbox and OneDrive migration; shared mailboxes do not require an additional user-data migration license.
- Available through EA, CSP, Web Direct and eligible commercial channels as supported. [Microsoft FAQ](https://www.microsoft.com/licensing/faqs/5), [Orchestrator](https://learn.microsoft.com/en-us/microsoft-365/migration/migration-orchestrator-1-overview).
- **Canadian official public list price not found**. Independent reseller [AppDirect marketplace](https://catalog.appdirect.com/en-us/apps/454419/microsoft-cross-tenant-user-data-migration/editions) advertised **USD $15/user** (marketplace listing may use a one-year billing term to represent the one-time entitlement). This is **NOT** a verified CAD Microsoft price. A US CSP price-list reseller also lists SKU `CFQ7TTC0R2N9:0005` at **USD $15/user** (annual SKU, single-use migration entitlement): https://o365hq.com/subscriptions/cross-tenant-user-data-migration (verified September 28, 2026; prices can change). Confirm exact destination tenant SKU, billing terms and pricing with customer CSP or Microsoft account team.
- Microsoft licensing FAQ states that the **destination tenant should purchase** CTUDM. The assigned entitlement may be on either source or target as allowed by migration documentation. Record offer, purchasing tenant, assignment eligibility and official advice before purchase.

### Cross-Tenant Shared Data Migration (CTSMDM) — native SharePoint sites

- Separately licensed from CTUDM. **Available to Enterprise Agreement customers only according to Microsoft's current site migration documentation**.
- Billed/entitled by **100 GB of data moved** with documented 20% storage grace. Do not invent a commercial price: **quote needed** from Microsoft account team. Not a general CSP-supported entitlement.
- Sites max 5 TB or 1 million items, no pre-existing target sites, no delta pass, limitations for Customer Key and app/workflow dependencies. [Official requirements](https://learn.microsoft.com/en-us/microsoft-365/migration/cross-tenant-sharepoint-migration).
- For CSP customers without EA use a third-party tool whose capabilities have been verified against the actual site inventory.

### Microsoft FastTrack

- Microsoft cross-tenant FastTrack program is **invitation-only preview**, currently notes a minimum of **150 migration licenses** and CTUDM SKU requirement. Not a guaranteed free service in a typical 5- to 50-user MSP customer move. [Official FastTrack](https://learn.microsoft.com/en-us/microsoft-365/fasttrack/cross-tenant-migration).

## 4. Example budget (150 users, 2 months overlapping source and target)

| Item | Quantity | Calculation | Result |
|---|---:|---|---:|
| Destination M365 Business Premium | 150 x 2 months | 150 × CAD 29.80 × 2 | **CAD 8,940** |
| Destination M365 E3 alternative | 150 x 2 months | 150 × CAD 52.90 × 2 | **CAD 15,870** |
| CTUDM illustrative reseller **USD** price | 150 once | 150 × USD 15 | **USD 2,250** |
| SharePoint third-party or EA-only native license | variable | Quote after GB/site/object assessment | **Not priced** |
| Extra source subscription costs | variable | Existing commitments may continue | **Not priced** |
| DNS/telephony/carrier/vendor/consultant | variable | Quote | **Not priced** |

The above assumes all 150 destination accounts require full baseline licenses for 2 months. It is NOT a total cost of ownership or a commitment to a 2-month project. Annual subscription commitments may still be payable beyond the illustrative period. A fresh quote is essential.

## 5. Commercial licensing gates before execution

- Record source and target exact SKU IDs/servicePlan IDs, quantities, tenant agreement types, reseller, renewal and cancellation rules; NCE term commitments may not be canceled early without penalties.
- Ensure M365 E3/E5/Business Premium licenses match security capability, not just mail/Office features; enforce Teams plan and region support.
- Do not assign Exchange/OneDrive-producing target licenses until **after** Microsoft cross-tenant identity mapping preparation, as documented by Microsoft.
- Keep source eligible licenses running during migration/coexistence; do not deprovision users or mailboxes early.
- Confirm legal hold/retention and Purview/P2 feature gaps on target. Premium security features cannot be faithfully rebuilt under lower target SKUs.

## 6. Third-party supplier price verification (not M365 licenses)

- **ShareGate Migrate Essentials:** vendor website currently advertises **starting at $5,995** for tenants with up to 250 employees, for SharePoint/Teams/Planner/OneDrive/file shares. The page does not resolve an authenticated Canadian quote here: **verify displayed currency, contract term, tax and modules** with vendor before treating as CAD project cost. See https://sharegate.com/pricing . Do not assume Essentials includes Exchange Online mailbox moves (check tier).
- **ShareGate Enterprise:** vendor website advertises starting at **$17,995** for larger deployments; verify currency and term and required workloads before procurement.
- **BitTitan MigrationWiz:** product selection depends on mailbox, Teams, public folders, SharePoint and *Tenant Migration Bundle* license types. Verify current official reseller/partner quote per workload: https://help.bittitan.com/hc/en-us/articles/36203678661531-Which-Migration-License-Do-I-Need .
- **Quest On Demand Migration / AvePoint Fly:** vendor contract quotes; their per-workload support and concurrency limitations must be validated in a pilot.

**Costing rule:** don't mix an unverified USD-priced migration tool fee into a CAD estimate. In the migration budget, attach official CAD customer-specific quotes for every commercial license and third-party provider.
