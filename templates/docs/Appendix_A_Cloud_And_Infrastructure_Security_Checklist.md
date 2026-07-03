# Appendix A — Cloud & Infrastructure Security Checklist

> Gate: run before build (design review) and again before launch. Every unchecked box needs a written justification.

## Identity & Access (IAM) — the #1 breach source
- [ ] Root/global-admin account: MFA enabled, no access keys, used only for break-glass.
- [ ] All human access via SSO/federation with MFA; no long-lived passwords.
- [ ] No static credentials in code, config, images, or CI variables — workloads use roles / managed identities / workload identity.
- [ ] Every role follows least privilege; no `*:*` policies; permissions reviewed against actual usage.
- [ ] Temporary credentials everywhere; any long-lived key has an owner, rotation schedule, and expiry.
- [ ] Separate accounts/subscriptions/projects for prod vs non-prod.
- [ ] Access reviews scheduled (quarterly at minimum); offboarding revokes access same-day.

## Network
- [ ] Nothing is internet-facing except the intended edge (CDN/WAF/LB); databases and app servers live in private subnets.
- [ ] Security groups / NSGs: default deny; rules reference groups, not broad CIDRs; no `0.0.0.0/0` on SSH/RDP/DB ports.
- [ ] Admin access via SSM Session Manager / Bastion with identity-aware access — no public SSH.
- [ ] Service-to-service traffic uses private endpoints/PrivateLink where available (data never rides the public internet).
- [ ] WAF in front of public endpoints; DDoS protection enabled.
- [ ] VPC/NSG flow logs enabled on production networks.
- [ ] Egress is controlled/monitored (compromised workloads exfiltrate via egress).

## Data
- [ ] Encryption at rest on every store (disks, DBs, buckets, queues, backups) — customer-managed keys where compliance requires.
- [ ] Encryption in transit everywhere (TLS ≥ 1.2), including service-to-service.
- [ ] Object storage: block-public-access ON at the account level; access via signed URLs or IAM only.
- [ ] Data classified (public/internal/confidential/PII) and controls mapped to classification.
- [ ] Backups: automated, encrypted, access-restricted, in a separate account/region, and **restore actually tested**.
- [ ] Data retention & deletion implemented (not just documented).
- [ ] PII minimized: collect only what's needed; masked/tokenized in non-prod environments.

## Secrets & Keys
- [ ] All secrets in a vault (Secrets Manager / Key Vault / Secret Manager); zero secrets in repos or plaintext env files.
- [ ] Rotation enabled (automated where possible); a leaked-secret revocation runbook exists.
- [ ] KMS keys: least-privilege key policies; usage logged; envelope encryption for large data.

## Logging, Detection & Response
- [ ] Cloud audit logging (CloudTrail / Activity Log / Audit Logs) ON in all regions, centralized, tamper-protected, retained per policy.
- [ ] Alerts on: root/admin usage, IAM policy changes, disabled logging, unusual API activity, public-exposure changes.
- [ ] Threat detection service enabled (GuardDuty / Defender for Cloud / Security Command Center).
- [ ] Incident response plan exists: severity levels, roles, communication, and a practiced tabletop exercise.

## Platform Hygiene
- [ ] Everything is Infrastructure as Code, peer-reviewed; no console-clicked "snowflake" resources in prod.
- [ ] IaC scanned for misconfigurations in CI (tfsec/Checkov or equivalent).
- [ ] Compute images/containers: minimal base, scanned for CVEs, rebuilt regularly, no root user.
- [ ] Patching strategy defined for anything not fully managed.
- [ ] Config/compliance monitoring (AWS Config / Azure Policy / GCP Org Policy) enforcing the rules above continuously.

---
