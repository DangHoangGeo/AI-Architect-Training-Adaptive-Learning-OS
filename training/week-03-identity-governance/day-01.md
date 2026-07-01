# Week 03 Day 1 — Concept foundation: Microsoft Entra ID tenants, directories, and authentication

## Goal
Understand how Microsoft Entra ID (formerly Azure AD) structures identities, tenants, and authentication flows, and why the right tenant design prevents access control failures from the start. Apply this to a professional services firm managing internal staff, external contractors, and a recent insider threat.

## Why this matters
A law firm or consulting company that puts all identities — partners, associates, external counsel, and temporary contractors — in a single flat directory with no governance will eventually experience what happened to a large accounting firm in 2023: a contractor whose engagement ended 6 months prior still had active credentials that accessed client workpapers. Entra ID tenant and authentication design is the foundation of every access control decision that follows.

## Core concept

1. **One tenant per organization is the standard baseline.** A Microsoft Entra ID tenant is a dedicated instance of the directory service tied to a domain (e.g., `northstarlegal.com`). You should not create multiple tenants for different departments — it creates identity fragmentation, duplicate licensing costs, and breaks cross-department Conditional Access. The exception is strict regulatory isolation (e.g., a subsidiary with different compliance requirements).

2. **External identities have two models with different trust levels.** B2B Collaboration (guest accounts) lets external users sign in with their own organizational identity (e.g., a contractor's `@contoso.com` account). Entra External ID (formerly CIAM) is for customer-facing apps. For contractors at a law firm, B2B guest accounts in the law firm's tenant — with restricted access via access packages — is the correct pattern.

3. **Authentication strength matters for privileged roles.** Password-only authentication is insufficient for partners with access to client data. Conditional Access policies can enforce MFA, specific authentication methods (FIDO2, certificate-based), and named location controls. The AZ-305 exam frequently tests which authentication method is required for Privileged Identity Management (PIM) activation.

4. **Hybrid identity requires Entra Connect Sync or Entra Cloud Sync.** If the law firm has on-premises Active Directory (running since 2005), users' on-premises identities must be synchronized to Entra ID. Entra Connect Sync handles complex scenarios (multiple forests, writeback). Entra Cloud Sync is lighter-weight for simple single-forest scenarios. Password Hash Sync vs. Pass-through Authentication vs. Federation (ADFS) each have different offline behavior and security trade-offs.

5. **Insider threat response requires audit logs and Identity Protection.** Entra ID Identity Protection uses ML to detect risky sign-ins (impossible travel, leaked credentials, unfamiliar locations). After an insider incident, the first forensic step is the Entra ID audit logs and sign-in logs — these show every access event. Retention is 30 days in Entra ID Free, 90 days with P1/P2 license — a critical detail for incident response.

## Learn — write notes answering these

- A law firm has 50 partners, 200 associates, and 80 external contractors from 12 different organizations. Which Entra ID identity type is correct for each group, and what is the licensing implication for each?
- What is the difference between a "member" user and a "guest" user in Entra ID, and which one has more default permissions to enumerate the directory? Why is this a risk?
- The firm's CISO asks: "Can we ensure that if a contractor's home organization has compromised credentials, they cannot access our tenant?" What Entra ID feature addresses this at the authentication level?
- What is the maximum sign-in log retention period without additional tooling, and what is the recommended Azure service to extend this for insider threat forensics?

## Micro exercise

**Scenario:**
> **Northstar Legal LLP** is a 250-person corporate law firm in London. They recently discovered that a former IT contractor — who left 8 months ago — accessed confidential M&A deal documents through a guest account that was never disabled. The contractor used their personal Microsoft account to authenticate (it had been added as a guest). The firm currently has no MFA enforced, no Conditional Access policies, and no process for disabling contractor accounts upon contract end. The IT director has 60 days before the ICO (UK data regulator) requires evidence of remediation.

Your answer must include:
- The immediate remediation steps for the compromised guest account scenario (3 steps, in order)
- An authentication policy design for the three user groups (partners, associates, contractors) specifying MFA requirement and authentication method
- The Entra ID license tier required to implement your proposed Conditional Access policies, and the cost per user for contractor guest accounts
- One automated control that would have prevented the 8-month dormant account from remaining active

## Reflection question
You enforce MFA for all users including contractors. A senior partner calls the help desk saying MFA is "too disruptive" when working from a hotel in New York during a deal close. How do you design Conditional Access to reduce friction for named trusted locations without compromising security, and what is the residual risk of that decision?

## Prior concept connection
Week 2 established network boundaries — subnets, NSGs, private endpoints. Identity is the complementary layer: even with perfect network isolation, a compromised valid credential bypasses every network control. Entra ID Conditional Access can enforce network location as an additional check ("only allow access from known IPs or compliant devices"), tying the identity layer directly to the network zones designed in Week 2.

## AI coach instructions
Ask the learner to write their answer before providing any feedback. Watch for: (1) recommending Entra ID P2 without justifying why P1 is insufficient for the stated requirements — exam and real-world scenarios often only need P1, (2) not identifying that guest users can enumerate the directory by default (the "Guest user access restrictions" setting is often missed), (3) proposing to "disable" a guest account without understanding the correct remediation is to remove the guest object and revoke all active sessions/refresh tokens. Probe: "What specific Entra ID setting allows you to automatically expire guest access after 90 days? Where in the portal is it configured?" Record any authentication model confusion in `memory/mistakes.md`.

## Completion criteria
- Three immediate remediation steps written in order
- Authentication policy designed for all three user groups with specific MFA method stated
- License tier requirement justified with cost figure
- Automated control named and described
- AI reviewed from cloud architect, security reviewer, and product manager perspectives
- Mistakes recorded and progress updated
