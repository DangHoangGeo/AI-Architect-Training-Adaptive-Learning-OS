# Week 01 Day 1 — Cloud service models and shared responsibility

## Goal
Understand the three cloud service models (IaaS, PaaS, SaaS), what Microsoft manages vs. what you manage in each, and why this matters when designing a production system.

## Why this matters
Misunderstanding the shared responsibility boundary is the source of many real production breaches. When a team moves to PaaS and assumes "Azure handles security," they often leave application-layer vulnerabilities unpatched. Architects who understand the model know exactly where their responsibility starts.

## Core concept
In every cloud service model, responsibility for security, patching, and operations is split between the cloud provider and the customer. The split changes depending on which model you choose:

- **IaaS** (Virtual Machines): You manage OS, runtime, application, data, identity. Azure manages physical hardware, network, and hypervisor.
- **PaaS** (App Service, Azure SQL): You manage application code, data, and identity configuration. Azure manages OS, runtime, and infrastructure.
- **SaaS** (Microsoft 365): You manage data and user configuration. Azure manages everything else.

The key architect question is: **What control do I give up, and what operational burden do I gain in return?**

## Learn — write notes answering these

- What does "shared responsibility" mean and why does it matter to an architect (not just a security team)?
- If a customer stores sensitive data in Azure Blob Storage and a breach occurs, who is responsible for what?
- Name one scenario where IaaS is the right choice over PaaS, and explain why.
- What is one common mistake teams make when migrating a VM workload to PaaS?

## Micro exercise

**Scenario:**
> A retail bank's IT team runs a customer-facing loan application portal on-premises. It uses Windows Server IIS, SQL Server, and a custom middleware layer. The CTO wants to move it to Azure in 90 days. The team has no Azure experience. The application handles personally identifiable financial data.

Your answer must include:
- Which service model (IaaS, PaaS, or hybrid) you recommend and why.
- One service model you explicitly reject and why.
- One shared responsibility risk specific to financial data in this scenario.
- One cost implication of your choice vs. the alternative.

## Reflection question
If your recommended model is breached at the application layer, who is responsible: Microsoft or the bank? What would the bank's incident report say?

## Prior concept connection
This is Day 1 — no prior days to connect. But note: the concept of "who owns what" will reappear every week. Security (Week 7), identity (Week 3), and IaC (Week 8) all require knowing where your responsibility boundary is.

## AI coach instructions
Do not provide the model choice before the learner answers. After they submit, review using cloud architect and product manager perspectives. Ask: "Does your model choice account for the team's operational maturity, not just technical fit?" If the security implication is missing or vague, flag it and update `memory/mistakes.md`.

## Completion criteria
- Learner wrote a specific answer with a named service model choice.
- AI reviewed it from architect and PM perspectives.
- Any mistake added to `memory/mistakes.md`.
- Progress updated.
