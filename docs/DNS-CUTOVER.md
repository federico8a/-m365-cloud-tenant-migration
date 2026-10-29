# DNS, domain release and coexistence plan

**Rule:** audit DNS on day one; prepare staging records and customer change access early; switch the **production custom domain and mail-routing DNS during cutover**, not during initial discovery.

## T-21 to T-7 days — inventory and design

- Identify registrar vs authoritative DNS host, NS, DNSSEC, delegation, owners, API change permissions and recovery contacts. Copy complete DNS zone, including third-party records that are **not** Microsoft 365 related.
- Audit root and subdomains: MX, `autodiscover`, SPF (`TXT`), DMARC (`_dmarc`), DKIM selectors (`selector1._domainkey`, `selector2._domainkey`), Teams/Skype legacy records, MX for secondary domains, MTA-STS, TLS-RPT, BIMI, verification TXT records and any custom sender systems/scanners/printers/CRMs.
- Confirm anti-spam gateways/relay and mail flow coexistence, shared SMTP namespace, external recipients, third-party application URLs and site hostnames; stage alternate routing `*.onmicrosoft.com` addresses.
- Choose whether the users retain `@sourcecustom.com` or use `@targetcustom.com`. This decision dictates whether custom domain transfer is required at all.
- Target tenant accounts can be prepared with a target staging domain from the beginning. Do **not** assume the custom source domain can exist simultaneously in both tenants.

## T-48 to T-24 hours — TTL and final preparation

- Lower TTLs for relevant records to e.g. 300 seconds **if your DNS host allows**. This helps only after prior TTL caches expire and does not guarantee same-minute propagation. Leave unrelated records intact.
- Obtain authorized source tenant custom-domain release plan; inventory all blockers: UPNs, shared/resource mailboxes, contacts, proxyAddresses, groups, Teams-connected groups, mail-enabled security/distribution groups and default/admin domains. Domain cannot be removed until blockers are cleared.
- Stage precise target MX, Autodiscover, SPF, DKIM, DMARC and verification record values as issued by Tenant B's admin center. **Do not invent DKIM CNAME targets**: they are tenant/domain-specific. Keep SPF valid across **all** senders in the transition (maximum 10 DNS lookups must be checked); coordinate signing and alignment.
- Require source/target emergency `.onmicrosoft.com` admin access; test break-glass and support/communications out-of-band.

## Change window — ordered hard gates

1. Freeze changes/accepted-domain aliases and obtain GO from customer, DNS owner, Messaging, Identity, Security, Compliance.
2. Verify migrated mailbox state / supported cutover, and coexistence forwarding where applicable. Ensure source tenant release doesn't strand users still in source.
3. Remove custom domain references from source identity/mail-enabled objects as authorized, then release verified domain from Tenant A. This step can have user sign-in and mail-flow impact. **Do not automatically purge source accounts to release domain.**
4. Verify same custom domain ownership in Tenant B by the proper Microsoft DNS TXT record and add it to target accepted domains.
5. Update target users' UPNs/SMTP aliases, shared/resource mailboxes, groups, transport rules and application/SSO callback configuration according to the approved mapping.
6. Change MX to the **Tenant B-specific** published target, Autodiscover, SPF, DKIM and DMARC as needed. Maintain any mail security gateway/relay configuration. Enable DKIM in tenant after records resolve.
7. Run external inbound/outbound tests (internal/external/from multiple sender providers), NDR check, message trace, header auth alignment, Autodiscover/Outlook new profile, MFA, Teams sign-in and SSO; log exact times.
8. Monitor mail queues, external delivery and propagation; maintain support staffing for at least 24–72 hours or customer's SLA.

## Contingency

- Reverting MX can route future inbound messages but will **not** reverse already moved mailboxes or credentials. Reversing a tenant domain release may be blocked by the new ownership and must be planned in the change window.
- Agree prior to GO on forward-recovery, temporary mail routing, delayed cutover and incident escalation thresholds. Site/OneDrive native moves do not offer incremental resync/automatic rollback.

## Read-only terminal audit

```powershell
./scripts/Test-DnsReadiness.ps1 -Domain 'example.com' -OutputPath './output/dns-before.json'
# Re-run post-cutover, compare and save privately under ./output/
./scripts/Test-DnsReadiness.ps1 -Domain 'example.com' -OutputPath './output/dns-after.json'
```

Official domain removal prerequisites: https://learn.microsoft.com/en-us/microsoft-365/admin/get-help-with-domains/remove-a-domain

See Microsoft's migration planning docs: https://learn.microsoft.com/en-us/microsoft-365/migration/microsoft-365-tenant-to-tenant-migrations
