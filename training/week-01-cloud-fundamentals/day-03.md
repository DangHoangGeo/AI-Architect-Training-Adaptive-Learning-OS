# Week 01 Day 3 — Functional vs non-functional requirements

## Goal
Learn to separate what a system must do (functional) from how well it must do it (non-functional), and practice extracting both types from a vague business request — which is what every real architect conversation starts with.

## Why this matters
Most system failures are non-functional failures: the system works but is too slow, too expensive, not available enough, or not secure enough. Architects who cannot extract non-functional requirements from a stakeholder conversation design systems that technically function but fail in production.

## Core concept
**Functional requirements** — what the system does:
- "Users can upload a document."
- "The system sends an email confirmation."
- "Admins can view all orders."

**Non-functional requirements (NFRs)** — how well it does it:
- **Performance**: "Page load < 2 seconds at P95."
- **Availability**: "99.9% uptime = max 8.7 hours downtime/year."
- **Scalability**: "Must handle 10x traffic spike without manual intervention."
- **Security**: "No PII accessible without authentication and audit log."
- **Compliance**: "All data stored in EU regions."
- **Recoverability**: "RTO < 4 hours, RPO < 1 hour."
- **Cost**: "Monthly infrastructure cost < $5,000 at launch."

NFRs drive architecture decisions far more than functional requirements. Two systems with identical functional requirements may have completely different architectures because of different NFRs.

## Learn — write notes answering these

- A product manager says "the system needs to be fast and secure." What follow-up questions do you ask to turn that into measurable NFRs?
- Which NFRs most directly affect your choice between App Service, Container Apps, and AKS?
- What is the danger of designing only to functional requirements in a regulated industry?
- Name one NFR that conflicts with cost efficiency and explain the trade-off.

## Product framing (write this before your design)

> **User pain:** A startup's operations team manually processes 200 supplier invoices per day via email. They miss payment deadlines because the inbox is chaotic.
> **MVP constraint:** The simplest version that proves value is automatic extraction and routing — not full ERP integration.
> **Success metric:** Time-to-approve per invoice drops from 4 days to < 4 hours within 30 days of launch.

## Micro exercise

**Scenario (continue from the product framing above):**
> The startup wants to build an invoice processing portal on Azure. A supplier uploads a PDF, the system extracts key data (vendor, amount, due date), and routes the invoice to the right approver. The startup has 5 internal users now but expects 50 suppliers and 20 approvers in 6 months.

Your answer must include:
- 3 functional requirements.
- 4 non-functional requirements with specific, measurable values (not "fast" or "secure").
- One NFR that would change the entire architecture if the value were doubled (e.g., availability 99.9% → 99.99%).
- One functional requirement you are explicitly deferring to V2 and why.

## Reflection question
If you presented these requirements to a developer, which NFR would they be most likely to ignore, and what would break in production as a result?

## Prior concept connection
Yesterday you placed resources in regions. Today you see that NFRs like compliance and data residency directly determine which regions are available to you. Your region choice was an implicit NFR decision. Making it explicit protects you when requirements change.

## AI coach instructions
After the learner submits, check: are the NFRs measurable? ("Secure" is not measurable. "No PII in logs, all access authenticated, audit trail retained 90 days" is measurable.) If the learner lists only functional requirements, ask them to identify which NFR they implicitly assumed. Update memory if NFR extraction is weak.

## Completion criteria
- Learner wrote at least 3 functional and 4 measurable non-functional requirements.
- AI reviewed with architect and PM perspectives.
- Mistakes added to `memory/mistakes.md`.
- Progress updated.
