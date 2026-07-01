# Week 01 Day 5 — Basic web application architecture and executive communication

## Goal
Design a complete basic web application architecture on Azure from first principles, then practice explaining it to a non-technical executive in plain language. Being able to do both is what separates a senior architect from a strong engineer.

## Why this matters
An architecture that cannot be explained is an architecture that cannot be funded, approved, or operated by a team that didn't build it. The skill of translating a technical design into a business narrative is required for every architecture review, every project kickoff, and every "why are we spending this much on Azure?" conversation.

## Core concept
A basic Azure web application architecture typically includes:

```
[Users] → [Azure Front Door / Application Gateway] → [App Service / Container Apps]
                                                          ↓
                                               [Azure SQL / Cosmos DB]
                                                          ↓
                                               [Azure Key Vault] (secrets)
                                                          ↓
                                               [Azure Monitor / App Insights] (observability)
```

Key decisions in this architecture:
- **Ingress**: Front Door (global, WAF included) vs Application Gateway (regional, WAF available) vs none.
- **Compute**: App Service (simplest PaaS) vs Container Apps (container-native) vs AKS (most control).
- **Data**: Azure SQL (relational, familiar) vs Cosmos DB (global distribution, flexible schema).
- **Secrets**: Key Vault with managed identity — never hardcoded credentials.
- **Observability**: Application Insights for application telemetry + Azure Monitor for infrastructure.

## Learn — write notes answering these

- What is the minimum viable set of Azure components for a web application that is secure by default?
- Why is Azure Front Door used instead of just an App Service with a public IP?
- What does "stateless compute" mean, and why does it matter for horizontal scaling?
- A junior engineer asks "can we just put the database connection string in the app settings?" What is your complete answer?

## Product framing (write this first)

> **User pain:** A growing logistics company manages shipment tracking via a spreadsheet shared over email. Tracking information is always out of date and customer queries take 30 minutes to answer.
> **MVP constraint:** A web portal where customers log in, see their shipment status, and get automated email updates — no ERP integration yet.
> **Success metric:** Average customer query response time drops from 30 minutes to self-serve in < 30 seconds.

## Micro exercise

**Design the architecture:**
Design the Azure infrastructure for the logistics company's MVP shipment tracking portal. Assume: 500 concurrent users at peak, data stored in Azure, no existing Azure infrastructure.

Your answer must include:
1. Named Azure services for each layer (ingress, compute, database, secrets, observability).
2. One security decision with justification (e.g., "no public database endpoint because...").
3. One cost decision with the trade-off (e.g., "App Service B2 instead of P1v3 for dev because...").
4. A 5-bullet executive summary that a non-technical CEO could read and understand why this architecture was chosen.

## Reflection question
A product manager asks: "We're launching in 3 weeks. What is the one thing in your design that, if we got wrong, would embarrass us publicly?" What is your answer?

## Prior concept connection
This week covered service models (Day 1), regional placement (Day 2), requirements (Day 3), and trade-offs (Day 4). Today you apply all of them. Your architecture should reference: which service model each component uses, which region it's in, which NFRs it satisfies, and what trade-offs you made. If any of those are missing, the design is incomplete.

## AI coach instructions
After the learner submits, check: (1) Is Key Vault used for secrets? (2) Is there any public database exposure? (3) Is the executive summary free of jargon? If the summary uses words like "containerization," "NSG," or "PaaS" without explanation, it fails the executive communication test. Push the learner to rewrite it. Score the executive summary separately.

## Completion criteria
- Learner designed a complete architecture with named services.
- Executive summary produced and reviewed for clarity.
- AI reviewed with architect, PM, and security perspectives.
- Mistakes added to `memory/mistakes.md`.
- Progress updated. Learner is ready for the Week 1 test.
