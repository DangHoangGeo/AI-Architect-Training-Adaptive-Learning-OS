# Week 09 Day 2 — Azure service mapping: RAG Ingestion and Retrieval Pipeline

## Goal
Map each stage of a production RAG pipeline to specific Azure services, understand their limitations and cost models, and justify why Azure-native choices are preferred over OSS alternatives in a regulated legal tech context. You will produce a service selection table you can use in interviews.

## Why this matters
Choosing LangChain + Pinecone for a law firm's contract review system means your vector store lives outside Azure, breaking data residency guarantees. Your CTO will ask why you chose an external dependency when Azure AI Search does the same job. If you cannot articulate the trade-off, you will lose the architect's trust before the first line of code is written.

## Core concept

1. **Azure Document Intelligence (formerly Form Recognizer)** is the correct ingestion service for contracts. It understands document structure — headings, tables, checkboxes, signature blocks — and produces structured JSON output. Using a generic PDF text extractor loses clause hierarchy, which degrades retrieval accuracy.

2. **Azure AI Search is the managed vector store.** It supports hybrid search (keyword + vector), integrated vectorization (chunking and embedding via a skillset), and per-document security trimming via `search.in` filters. This is the only Azure-native service that can enforce per-tenant document isolation at query time.

3. **Azure OpenAI Service provides the embedding and generation models.** `text-embedding-3-large` is the current recommended embedding model. For generation, `gpt-4o` is the default; deployment to a provisioned throughput unit (PTU) is required when latency SLAs are firm.

4. **Azure Functions or Azure Container Apps host the orchestration logic.** The orchestration layer assembles the prompt, calls Azure AI Search, and calls Azure OpenAI. It must be stateless. Use Durable Functions only if you need human-in-the-loop workflow coordination (which legal review gates require).

5. **Azure Blob Storage (with Lifecycle Management) holds raw documents.** Ingested contracts are immutable. Blob Storage with versioning and legal hold policies satisfies the law firm's document retention obligations. Access is via managed identity only — no SAS tokens in production.

6. **Alternatives rejected and why:**
   - Pinecone: data leaves Azure, breaks UK residency.
   - LangChain: adds OSS dependency for orchestration that Azure Durable Functions handles natively with better observability.
   - Azure Cognitive Search (old name): same service, but verify the SKU — Basic does not support semantic ranking or vector search.

## Learn — write notes answering these

- What is the difference between Azure AI Search's keyword search, vector search, and hybrid search? When does hybrid search outperform pure vector search for legal documents?
- What is an Azure AI Search "skillset" and how does it enable integrated vectorization without writing custom chunking code?
- Azure OpenAI provisioned throughput (PTU) vs. pay-as-you-go: what problem does PTU solve, and what is the minimum commitment that makes PTU cost-effective?
- What Azure service would you use to queue documents for ingestion when the law firm uploads 200 contracts simultaneously, and why is synchronous processing the wrong choice?

## Micro exercise

**Scenario:**
> LexAI has completed its MVP architecture on paper. Now the engineering team needs to decide exactly which Azure SKUs and services to deploy. The law firm has stated: (a) query response time must be under 3 seconds for 95% of queries, (b) the system will process 500 contracts per week on ingestion, and (c) they need audit logs showing which attorney queried which document and what the AI returned.

Your answer must include:
- A service selection table with columns: Pipeline Stage | Azure Service | SKU/Tier | Justification | Rejected Alternative.
- How you achieve the 3-second query latency target (name the specific levers: index configuration, embedding model, PTU vs. PAYG).
- Where audit logs are written, which Azure service stores them, and how long they are retained.
- One cost optimization you would apply to the ingestion pipeline to avoid paying for redundant embedding re-computation on unchanged documents.

## Reflection question
Azure AI Search has a maximum vector dimension limit and a maximum index size per SKU. If LexAI onboards 50 law firms each uploading 10,000 contracts, how does your index design scale — and at what point does a single shared index become a liability?

## Prior concept connection
In Week 09 Day 1 you defined the five pipeline stages. Today you are filling in the specific service names. If your Day 1 answer had gaps in stage definition, reconcile them now before completing the service table.

## AI coach instructions
The learner must produce the service table — do not produce it for them. Watch for: (1) not specifying SKU/tier (e.g., "Azure AI Search" without saying Standard S1 or higher for vector support), (2) missing the queue between upload and ingestion, (3) no mention of audit logging to Azure Monitor or Log Analytics. Probe: "How does Azure AI Search enforce that Firm A cannot retrieve Firm B's documents at query time — show me the filter syntax." Update `memory/weak_areas.md` if the learner cannot explain security trimming filters.

## Completion criteria
- Learner produced a service selection table with at least five rows covering all pipeline stages.
- Learner named a specific latency optimization technique (PTU, semantic ranker tuning, or hybrid search weight adjustment).
- Learner identified Azure Monitor/Log Analytics for audit logging with a retention policy.
- Learner identified a caching or deduplication strategy to avoid re-embedding unchanged documents.
- AI reviewed with cloud architect and product manager perspectives.
- Any mistakes added to `memory/mistakes.md`.
