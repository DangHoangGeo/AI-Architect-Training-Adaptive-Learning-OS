# Client Brief Test — Template

Use this format for weeks 3, 6, 9, and 12 instead of the standard written test.
This format simulates a real consulting or pre-sales scenario: a stakeholder sends requirements, and the architect must produce a proposal.

## Purpose
Assess whether the learner can extract requirements from ambiguous input, make defensible architectural decisions, communicate to a business audience, and identify what is missing before committing to a design. This is the closest simulation to real senior architect work.

## Instructions to learner
1. Read the client email below as if you just received it.
2. Before proposing any architecture, write a **Clarifications needed** section: list 2–3 questions you would ask the client before starting. Then answer them yourself with reasonable assumptions.
3. Produce a **Architecture proposal** addressing the client's needs.
4. Produce a **Risk and trade-off summary** (3–5 bullet points).
5. Produce a **What we are NOT building** section (MVP scope discipline).
6. Produce a **5-bullet executive summary** the client can share with their CTO.

## Scoring (100 points)

| Area | Points |
|---|---|
| Clarifications quality — right questions asked | 10 |
| Requirements extracted correctly from the brief | 15 |
| Architecture components correct and justified | 25 |
| Risk and trade-off summary — honest and specific | 15 |
| MVP discipline — what was scoped out and why | 10 |
| Executive summary — clear, jargon-free, business-focused | 15 |
| Security and compliance addressed | 10 |

Passing threshold: 75/100

## Week-specific client brief

*(Replace this section with the week-appropriate brief when using this template.)*

---

**Week 3 example brief:**
> From: David Chen, CTO, Meridian Health Group
> Subject: Azure identity project — need your help
>
> Hi,
>
> We're moving our internal systems to Azure and need to sort out identity. We have about 800 employees, 12 apps, and we just acquired a smaller company with 150 users on a different Active Directory. Some apps need to be accessed by external contractors. We had a breach last year because a developer had admin access they didn't need, so the board is very focused on least privilege. We use Office 365 already.
>
> We want SSO, we want to make sure secrets aren't in code, and we want to audit who accessed what. Budget is not fixed but we don't want to overspend. Can you propose something?
>
> Thanks,
> David

---

**Week 6 example brief:**
> From: Priya Malhotra, VP Engineering, RetailEdge
> Subject: We can't see anything in production
>
> Hello,
>
> Our platform went down for 4 hours last Tuesday and we had no idea until customers called us. We run about 15 Azure services — App Service, Service Bus, Cosmos DB, Redis, a few Function Apps, and some VMs. We have some logs but they're all over the place. We set up some alerts last year but they fire constantly so the team ignores them.
>
> I need you to fix this. We need to know when something is about to fail before it fails. We also need to be able to investigate incidents fast. I don't know the Azure monitoring tools well but I've heard about Application Insights and Azure Monitor. Can you put together a proposal?
>
> Priya

---

**Week 9 example brief:**
> From: James Okafor, Head of Innovation, National Insurance Co.
> Subject: AI document processing — looking for architecture guidance
>
> Hi,
>
> We process about 50,000 insurance claims documents per month. Right now it's all manual. We want to use AI to extract key information — policy number, claim amount, incident date, names — and route claims automatically. Some documents are handwritten, some are PDFs, some are photos.
>
> We're a regulated company so data must stay in our Azure tenant and we can't send customer data to external services. Documents contain PII. We need an audit trail for every decision the AI makes. We've heard about Azure OpenAI but we don't know if it's the right tool.
>
> What would you build?

---

**Week 12 example brief:**
> From: Sarah Lim, CEO, CloudLedger (Series B startup)
> Subject: Architecture for scale — we need a real platform now
>
> Hi,
>
> We're a B2B SaaS company. We have 40 customers now but we're closing a deal that will add 200 enterprise customers in Q1. We're on Azure but everything is in one subscription, one App Service, one SQL database. I know that's going to break.
>
> Our biggest customers want: their data isolated from other customers, their own SLA, the ability to deploy in their own region (we have EU customers asking about GDPR), and a private network option. We also need zero-downtime deployments because one of our enterprise prospects made it a contract requirement.
>
> I need a roadmap from where we are now to a real multi-tenant platform. How would you do it?

---

## Memory update required
After scoring:
- Update `memory/progress.md`
- Update `memory/mistakes.md`
- Update `memory/weak_areas.md` if patterns appear
- Update `memory/session_logs/YYYY-MM-DD.md`
