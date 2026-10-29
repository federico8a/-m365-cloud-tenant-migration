# Post-cutover acceptance and recovery checklist

## Day 0 (GO/NO-GO)

- Mail: successful internal/external incoming/outgoing, shared mailbox permissions, delegates, calendar free/busy, reply to old x500 cache, meeting updates, mailbox archives and rules.
- DNS: MX, Autodiscover, SPF, DKIM selectors, DMARC and third-party relay; check headers and M365 message traces, not DNS alone.
- Users: UPN sign-in, MFA/TAP/password reset, target licenses, Conditional Access, mobile Outlook/Teams/OneDrive, Edge/Office device profiles.
- Content: OneDrive/SharePoint data, path depth, metadata and versions sample, source redirect links and ACLs, Teams chats/meetings/channel content where contracted.
- Endpoints: Intune reassignment/re-enrollment, compliance and encryption, endpoint protection/Defender alerts, platform-specific Autopilot/Apple/Android enrollment.
- Apps: SAML/OIDC SSO, vendor SCIM provisioning, enterprise apps/API consents, secrets/cert rotation, app registration redirects and connection strings.
- Security: Defender and Purview DLP/labels/holds/retention, audit export and backup, PIM roles, privileged emergency access.
- Business: Teams Phone inbound/outbound, queues, Power Platform apps/flows/gateways, Fabric dataset refresh, Planner/Forms/Bookings/Loop owners.

## Day 1–14 hypercare

- Monitor migration batch per-user outcomes; `Completed` for Teams chat may include some explicitly skipped content.
- Re-run inventory and compare object mapping and service owner acceptance. Preserve exceptions.
- Track helpdesk incidents (login, file access, Outlook profile, OneDrive sync, phone, mobile enrollment, line-of-business apps), monitor delivery failures/throttling and security controls.
- Obtain finance confirmation of double licensing period, commercial commitments, CSP partner entitlements and any third-party tool invoices.

## Source tenant retirement (separate approval)

Never auto-delete Tenant A. Confirm retained content, data residency, legal hold/eDiscovery/export obligations, source redirects, guest accounts, provider logging, carrier/certificates, billing cancellations, ownership of SaaS integrations and evidence retention. Rollback of a one-time native move is not guaranteed; use specific forward recovery and backups where technically supported.
