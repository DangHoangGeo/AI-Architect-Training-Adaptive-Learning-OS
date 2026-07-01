# Week 09 Day 3 — Design exercise: Prompt Versioning and Evaluation Pipeline

## Goal
Design a prompt versioning and evaluation system for a production legal AI application on Azure. You will define how prompts are stored, versioned, tested against a golden dataset, and promoted to production — treating prompts as first-class software artifacts, not hard-coded strings.

## Why this matters
A law firm's AI contract reviewer is running prompt version 1.3 in production. An engineer edits the system prompt to improve clause detection accuracy. The new version ships on Friday. On Monday, the firm's partners report that the AI is now incorrectly flagging standard limitation-of-liability clauses as high risk. Without a versioned prompt registry and a regression test suite, you cannot roll back, you cannot explain what changed, and you cannot prove to the firm that the system is behaving correctly. The reputational damage can terminate the contract.

## Product framing (write this first)
> **User pain:** Law firm partners cannot trust AI risk summaries because they change unpredictably when engineers update prompts, and there is no audit trail showing what prompt version produced a given output.
> **MVP constraint:** The evaluation pipeline must run in under 10 minutes so engineers can get feedback before merging a prompt change to main.
> **Success metric:** Zero prompt changes reach production without passing a 95% accuracy threshold on a 200-case golden dataset of pre-labeled contract clauses.

## Core concept

1. **Prompts are code.** They must live in source control (Git), have semantic version numbers (major.minor.patch), and be deployed through a CI/CD pipeline — not edited directly in the application configuration.

2. **A golden dataset is the test suite for prompts.** For contract review, this means 200+ contract excerpts with known ground-truth labels (e.g., "this clause IS a limitation of liability", "this clause IS NOT a penalty clause"). The dataset is fixed; prompts change, the dataset does not.

3. **Azure AI Foundry (formerly Azure AI Studio) Prompt Flow** provides a managed pipeline for prompt evaluation. It supports batch inference against a dataset, metric computation (accuracy, F1, groundedness, relevance), and run comparison across prompt versions.

4. **Azure Blob Storage or Azure DevOps Artifacts stores prompt versions.** Each prompt is a JSON file with: version, template text, system instruction, evaluation results, approval status, and author. The file is immutable once tagged.

5. **Promotion gates prevent untested prompts reaching production.** The CI/CD pipeline (Azure DevOps or GitHub Actions) runs the evaluation job; if accuracy < 95%, the pipeline fails. Only a passing build can update the Azure App Configuration key that points to the active prompt version.

6. **Human review of evaluation failures is mandatory.** Automated metrics catch regression; humans catch silent failures — cases where the AI produces plausible-sounding but legally incorrect output that still scores well on surface metrics. At least 5% of evaluation failures must be reviewed by an attorney before a prompt is approved.

## Learn — write notes answering these

- What is "groundedness" as an evaluation metric for RAG systems, and why does it matter more than accuracy alone for legal AI outputs?
- How does Azure AI Foundry Prompt Flow differ from a generic Azure DevOps pipeline for running prompt evaluations? What does it provide that a custom Python script does not?
- What is the risk of using LLM-as-a-judge (having a second model score the first model's output) as your only evaluation method?
- How do you version a system prompt separately from a user prompt template, and why does this distinction matter for legal applications?

## Micro exercise

**Scenario:**
> LexAI's engineering team now has three lawyers contributing to prompt design. Each lawyer has their own idea of how to phrase the system instruction for identifying "material adverse change" clauses in M&A contracts. Last week, two engineers merged conflicting prompt updates to the same configuration key, causing the production system to run a hybrid prompt that neither lawyer approved. The CTO has asked you to design a prompt versioning and evaluation system that prevents this from happening again.

Your answer must include:
- A version control and promotion workflow diagram (described in text or a numbered flow, not a visual): how does a prompt go from draft → tested → approved → production?
- The Azure services that store, evaluate, and activate prompts, and how they connect.
- The specific evaluation metrics you would use for an M&A contract clause detection task, and why.
- How you would handle the case where a new prompt version scores 97% overall but fails on a specific clause type (e.g., change-of-control clauses) at 78% accuracy.

## Reflection question
Your evaluation golden dataset was labeled by lawyers 18 months ago. The legal standard for "material adverse change" has since been refined by a high-profile court ruling. How do you detect that your golden dataset has become stale, and what is the process for updating it without introducing evaluation bias?

## Prior concept connection
In Week 09 Day 2 you built the service map for the RAG pipeline. Today's exercise adds a control plane on top of that pipeline. Identify exactly where in your Day 2 architecture the prompt registry and evaluation pipeline connect — which service triggers the evaluation job, and which service reads the active prompt version at query time.

## AI coach instructions
The learner must write the Product framing section before designing the system. Do not proceed to the scenario without it. Watch for: (1) storing prompts in the application database rather than a versioned artifact store, (2) running evaluation only on the full dataset average and missing per-clause-type breakdowns, (3) no human review gate in the promotion workflow. Probe: "If your evaluation pipeline passes at 96% but a lawyer flags that the AI is wrong on every change-of-control clause — what does your system do?" Update `memory/weak_areas.md` if the learner cannot describe a promotion gate with a blocking threshold.

## Completion criteria
- Learner wrote the Product framing section before the design.
- Learner described a promotion workflow with at least three gates (draft, tested, approved).
- Learner named specific evaluation metrics appropriate for clause detection (accuracy, precision/recall, groundedness).
- Learner addressed the partial failure scenario (high overall accuracy, low accuracy on one clause type).
- AI reviewed with cloud architect and product manager perspectives.
- Any mistakes added to `memory/mistakes.md`.
