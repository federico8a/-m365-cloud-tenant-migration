# Engineering risk register / blockers and third-party decision tree

| Priority | Risk / blocker | Mitigation / decision | Owner |
|---|---|---|---|
| CRITICAL | Assigning Exchange service plan creates target mailbox BEFORE CTIM | Hold target licensing, stamp GUID via official CTIM, verify MailUser, only then license | Exchange lead |
| CRITICAL | OneDrive target site already provisioned | Disable creation; validate absence before move; unsupported merge => third-party or alternative content approach | SharePoint lead |
| CRITICAL | Litigation/eDiscovery/retention/Customer Key blocks native move | Legal signoff; keep source and retention, design alternative archive/eDiscovery; never remove hold to bypass | Compliance |
| CRITICAL | Source custom domain still used by identities/groups/services | Enumerate blockers and staged remap, rehearsed release/change | Identity/DNS |
| HIGH | Teams channel content and meeting edge cases | Native orchestrator for chats/meetings only; evaluate Quest/AvePoint/ShareGate against sample objects; preserve known skips | Collaboration |
| HIGH | Native SharePoint site license unavailable to CSP customer | EA eligibility review; alternative qualified ShareGate/AvePoint/Quest or controlled content rebuild; POC on versions/permissions | Commercial |
| HIGH | Teams chat completion allows known skipped messages/threads | Collect per-user counts/thresholds; separately acknowledge skipped unsupported content | Collaboration |
| HIGH | Old appId/objectId, SAML, SCIM, OAuth secrets and federated credentials invalid in B | Re-register apps, vendor coordination, rotate credentials, re-consent and test every business-critical app | App owner |
| HIGH | Intune profile export incomplete, device ownership stays with A | Graph export is planning-only; staged device re-enrollment, Autopilot and platform-specific POC | Endpoint |
| HIGH | CA/MFA policy locks out migration operators | Report-only policies, test pilot group, separate break-glass identities, rollback policy plan | Security |
| HIGH | PSTN/Teams Phone number porting, SBC and emergency calling | Carrier order and E911 validation, test call flows, route contingency | Voice |
| MEDIUM | Unexpected source NCE/EA commitments | Costed financial plan, two-tenant coexistence overlap and cancellation terms | Finance |
| MEDIUM | Power Platform/Dataverse environment restrictions and connectors | Supported production/sandbox move, solution export/rebind for others; test URLs, gateway, app users | Platform |
| MEDIUM | Fabric Git deployment moves definitions but not data | Workspace recreation, refresh credentials, capacity, Data Gateway, data copy and validations | BI |
| MEDIUM | Reports and security history missing from destination | Explicit retention/export/data protection design rather than claiming full transfer | Security |
| HIGH | Graph beta behavior or permission changes | Only run with pilot and approved Graph SDK/module versions; API status can change; use native admin workflow if unsuitable | Migration lead |

## Decision tree for each workload

1. Microsoft-native **supported and eligible** for both tenants, licenses and cloud? Use native workflow with official validation and no fabricated commands.
2. Microsoft-native not complete (Teams channel workspace, apps, Intune devices)? Use native configuration recreation **where permitted**; preserve immutable-ID mapping and evidentiary tests.
3. Third-party required? Evaluate **Quest On Demand Migration** (complex Teams/Groups), **AvePoint Fly** (broad M365), **ShareGate** (SharePoint/Teams/Planner content), **BitTitan MigrationWiz** (mailboxes, user content, SharePoint/Teams offers); obtain product-specific written scope, feature test and pricing. Do **not** claim that any product copies Entra credentials, authentication sessions, historical security events or all service state.
4. No vendor/API support: label `MANUAL` or `NOT_MIGRATABLE`; contractually exclude the object, preserve source read access per retention rules, and document owner acceptance.

Python is for assessment, cost, mapping, reconciliation, evidence, and API integrations where Microsoft publicly supports that operation. Python **cannot** circumvent unsupported Microsoft workload APIs.

## Evidence / acceptance checklist

- [ ] Customer/owner written authorizations
- [ ] Complete inventories with zero unexplained read failures
- [ ] Product/SKU purchase confirmation + licensed users and GB
- [ ] Identity mapping stamped + GUIDs/aliases verified
- [ ] Exchange/ODSP destination absence proven
- [ ] Supported migration batch per-user validation
- [ ] Domain release and mail-flow test evidence
- [ ] Teams channel and chats separately sampled
- [ ] SharePoint versions/metadata/sites/permissions sampled
- [ ] Intune users/devices/apps/policies and CA tests
- [ ] Enterprise apps (SAML, OIDC, SCIM) critical path tested
- [ ] Purview/Defender policies and data retention disposition
- [ ] Finance/CSP/support/operational handover and source decommission approval
