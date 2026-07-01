# Week 09 Day 5 — Communication and refinement: Safety, Privacy, and Human Review Architecture

## Goal
Refine LexAI's architecture by designing the safety and privacy layer — the controls that prevent the AI from producing harmful legal advice, protect client confidentiality, and ensure every high-stakes output passes a human attorney review before reaching end users. You will produce a written architecture decision record (ADR) suitable for a client-facing security review.

## Why this matters
A law firm that deploys an AI contract reviewer without a human review gate is exposing itself to professional liability claims. In most jurisdictions, legal advice can only be given by a licensed attorney. An AI output that a client relies upon without attorney review is unauthorized practice of law. If LexAI cannot demonstrate a defensible human oversight architecture to its law firm clients, it will fail regulatory due diligence and lose the contract before going live.

## Core concept

1. **Safety in legal AI is not just about harmful content.** It includes: preventing the AI from giving definitive legal opinions (vs. identifying issues for attorney review), preventing hallucinated case law citations, and preventing the system from processing documents it should not have access to (authorization errors).

2. **Azure AI Content Safety provides configurable content filters.** For legal AI, the relevant concern is not violence or hate speech — it is "jailbreak" prompt injection and the model generating confident-sounding legal conclusions beyond the scope of the retrieved context. Custom blocklists and groundedness detection address this.

3. **The human review gate is a workflow, not just a UI.** In LexAI, every AI-generated risk summary must be reviewed by a qualified attorney before being delivered to the client. This requires: a task assignment system (who reviews what), an SLA (maximum time to review), an escalation path (what if no attorney is available), and an audit log (who approved what, when, with what modifications).

4. **Privacy by design means data minimization in the prompt.** The system prompt should never include the client's name, matter number, or identifying information unless required for the query. Personally identifiable information (PII) in retrieved chunks should be detected and flagged before injection into the prompt. Azure AI Language (PII detection) runs as a pre-processing step in the retrieval pipeline.

5. **Right to erasure is an architectural constraint.** When a law firm offboards, all their documents, embeddings, and chat history must be deleted — not just the raw files. The Azure AI Search index must support per-tenant index deletion or per-document deletion by a stable document ID that maps to Blob Storage. This must be tested before go-live, not discovered during a GDPR request.

6. **An Architecture Decision Record (ADR) documents why these choices were made.** For a legal tech client, the ADR is a deliverable — it demonstrates that safety and privacy were architectural priorities, not afterthoughts. It covers: the decision, the context, the options considered, the decision made, and the consequences.

## Learn — write notes answering these

- What is the difference between "content safety" (preventing harmful outputs) and "grounding" (preventing hallucination), and which Azure services address each?
- How does the "human-in-the-loop" pattern in Azure Durable Functions work for a review workflow where an attorney must approve before delivery — what triggers the workflow, what pauses it, and what resumes it?
- What is Azure Purview's role in a legal AI system that processes confidential client documents across multiple law firm tenants?
- PII detection in Azure AI Language operates on text. What happens when PII is embedded inside a table in a PDF contract — for example, a signatory's home address in a signature block? How does your architecture handle this?

## Micro exercise

**Scenario:**
> LexAI is preparing for its first enterprise security review by a Magic Circle law firm's IT security team. The firm has sent a 47-question security questionnaire. The most challenging questions are: (Q12) "How do you prevent the AI from generating legal advice beyond the scope of retrieved contract text?" (Q23) "What is your data deletion process when we terminate the contract?" (Q31) "How do you ensure attorney review before outputs reach our fee earners?" (Q38) "How do you detect and respond to prompt injection attacks embedded in uploaded documents?"

Your answer must include:
- A written response to each of the four questionnaire items (Q12, Q23, Q31, Q38) in the style of a security review response — factual, specific, naming Azure services and configurations.
- An Architecture Decision Record (ADR) for the human review gate design — covering: context, options considered (3 options minimum), decision made, and consequences (positive and negative).
- One change you would make to the architecture designed in Days 1-4 based on the security review findings.

## Reflection question
The law firm's security team asks: "If we use LexAI to review a contract that involves a merger where one party is a competitor of ours, how do you guarantee that the AI does not leak information about that deal to other LexAI clients?" What is the correct architectural answer, and what is the honest caveat about what no architecture can fully guarantee?

## Prior concept connection
This day synthesizes all of Week 9. Before writing the ADR, review your answers from Days 1-4. The human review gate workflow (Day 5) depends on the observability layer (Day 4) to trigger alerts when SLAs are breached. Explicitly reference how these two components interact.

## AI coach instructions
The learner must produce both the questionnaire responses and the ADR — do not write either for them. Evaluate the questionnaire responses for specificity (Azure service names and configurations, not generic statements). Evaluate the ADR for structure (context, options, decision, consequences). Watch for: (1) responses that say "we use Azure" without naming the specific control, (2) an ADR that lists only one option (defeating the purpose), (3) no honest caveat about the data leakage question (the honest answer is that logical isolation is never absolute and the firm must assess whether shared infrastructure is acceptable). Probe: "Your ADR says you chose Azure Durable Functions for the review gate. What is the failure mode if the Durable Functions storage account is unavailable?" Update `memory/progress.md` with Week 9 completion and add a score across all five days.

## Completion criteria
- Learner wrote specific security questionnaire responses naming Azure services and configurations for all four questions.
- Learner wrote a complete ADR with context, at least three options, a decision, and consequences.
- Learner identified one architectural change driven by the security review.
- Learner provided an honest caveat on the data leakage question.
- AI reviewed with cloud architect, security reviewer, and product manager perspectives.
- `memory/progress.md` updated with Week 9 completion status.
- Any mistakes added to `memory/mistakes.md`.
