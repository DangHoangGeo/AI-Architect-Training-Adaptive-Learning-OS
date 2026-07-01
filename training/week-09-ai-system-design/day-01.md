# Week 09 Day 1 — Concept foundation: AI Application Architecture for Legal Document Processing

## Goal
Understand the structural components of an AI application built on Azure — ingestion, embedding, retrieval, generation, and human review — and why each layer is a discrete architectural decision. By the end of this session, you can name the components of a production RAG system, explain where failures occur, and connect each component to a business requirement.

## Why this matters
A legal tech company that ships an AI contract reviewer without separating ingestion from retrieval will face a crisis when a client demands their documents be deleted. If you cannot isolate which pipeline processed their files, you face GDPR/data residency violations and potential malpractice liability. Treating the AI system as a single black box is the architectural mistake that ends contracts.

## Core concept

1. **AI application architecture is a pipeline, not a model.** The LLM is one component. The others — document ingestion, chunking, embedding, vector storage, retrieval, prompt assembly, generation, output filtering, and human review — each carry distinct failure modes and cost drivers.

2. **The ingestion layer determines everything downstream.** How you chunk documents (by page, by clause, by semantic unit) controls retrieval accuracy. A contract review system that chunks by page will fail to retrieve cross-page indemnity clauses correctly.

3. **Vector stores are not databases.** They do not enforce row-level security natively. If you store all clients' embeddings in one Azure AI Search index without tenant filtering, any query can surface another client's contract clauses.

4. **The generation layer must be separated from the grounding layer.** Prompt construction (what context to inject) is a policy decision; calling the LLM is a compute decision. Keeping them separate allows prompt versioning and A/B testing without redeploying infrastructure.

5. **Human review is not optional for legal use cases.** AI-generated contract risk summaries must have an attorney review gate before being surfaced to end users. This gate is an architectural component with its own workflow, SLA, and audit log — not a UI checkbox.

6. **Cost flows through tokens.** Every document chunk injected into a prompt costs money. A naive system that retrieves 20 chunks per query at 500 tokens each, for 1,000 queries per day, generates 10M tokens/day before even counting the response. Architecture decisions must include a token budget.

## Learn — write notes answering these

- What is the difference between a RAG pipeline and a fine-tuned model, and when would you choose each for contract review?
- Which Azure services map to the ingestion, embedding, retrieval, and generation stages?
- What does "grounding" mean in the context of a legal AI system, and why does it reduce hallucination risk?
- What failure mode occurs if the retrieval step returns irrelevant chunks, and who bears the consequence in a legal context?

## Micro exercise

**Scenario:**
> LexAI is a legal tech startup that has signed its first enterprise contract with a Magic Circle law firm. The firm processes 500 contracts per week — NDAs, MSAs, and IP licensing agreements — averaging 40 pages each. Lawyers want to ask questions like "does this contract include a liquidated damages clause?" and "what is the governing law?" The firm has strict data residency requirements: all documents must remain in the UK. They also prohibit their documents from being used to train any AI model.

Your answer must include:
- The five pipeline stages you would define (name them and describe data flow between them).
- Which Azure region and services you would use for each stage, and why UK South specifically.
- Where the tenant boundary sits to prevent one law firm's documents from being retrievable by another.
- What "no training data" means technically for Azure OpenAI Service, and which configuration setting enforces it.

## Reflection question
If the law firm's IT department asks "how do we know our documents never left the UK?", what Azure-native evidence can you produce — and what cannot be proven by logs alone?

## Prior concept connection
In Week 3 you studied Azure networking and private endpoints. Before answering, consider: does your AI pipeline need private endpoints, and at which stages would public endpoints be a compliance risk?

## AI coach instructions
Ask the learner to write out the five pipeline stages before revealing any structure. Watch for: (1) treating the LLM call as the entire system, (2) forgetting the human review gate, (3) not addressing tenant isolation in the vector store. If the learner does not mention data residency configuration in Azure OpenAI, probe: "How does Azure OpenAI handle your prompt data by default?" Update `memory/weak_areas.md` if the learner cannot name all five stages.

## Completion criteria
- Learner named and described at least four pipeline stages.
- Learner identified UK South as the required region and explained why.
- Learner addressed tenant isolation in the vector store.
- Learner correctly stated that Azure OpenAI does not use customer prompts for training by default (and knows where this is documented).
- AI reviewed the answer with cloud architect and product manager perspectives.
- Any mistakes added to `memory/mistakes.md`.
