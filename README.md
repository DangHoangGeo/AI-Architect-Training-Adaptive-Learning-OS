# AI Architect Training OS — Adaptive Learning OS

This repository is a production-ready self-learning operating system for becoming a high-level Azure Cloud Architect, AI Systems Architect, Product-minded Engineer, and DevOps practitioner.

It is designed for use inside VS Code with AI coding assistants such as Claude Code, Codex, GitHub Copilot Chat, or local AI agents that can read and write files.

## The learning model

Every week follows a strict progression:

1. **Daily training** — learn one concept deeply.
2. **Micro exercise** — apply the concept immediately.
3. **Memory update** — record mistakes, weak areas, and progress.
4. **Weekly test** — validate understanding before building.
5. **Weekly workshop** — create architecture artifacts and Bicep infrastructure.
6. **Weekly review** — score the work, extract lessons, and adapt the next week.

The system is intentionally not random. The AI coach must use the roadmap, current memory, previous mistakes, and current week/day to decide what to teach next.

## Quick start

1. Open this folder in VS Code.
2. Configure your AI tool to use `system/system_prompt.md` as the main instruction file.
3. Ask the AI:

```text
/start-training
```

4. At the end of every session, ask:

```text
/end-session
```

5. Do not start a workshop until the weekly test is passed.

## Important folders

- `system/` — AI operating rules, memory protocol, session commands.
- `skills/` — role-specific behavior files for AI: architect, PM, DevOps, security, AI engineer, cost optimizer, interviewer, principal engineer.
- `memory/` — persistent learner memory written as Markdown.
- `roadmap/` — 12-week curriculum, skill matrix, weekly flow.
- `training/` — 60 daily lessons, five per week.
- `tests/` — 12 weekly tests and scoring rubrics.
- `workshops/` — 12 final hands-on projects with architecture and Bicep starters.
- `enterprise-systems-examples/` — 12 worked case studies of real-world enterprise-grade systems (banking ledger, e-commerce, airline reservations, EHR, ERP integration, payments, multi-tenant SaaS, fraud detection, streaming, logistics, brokered AI agent platform, autonomous agent sandbox platform), each with a business scenario, PM brief, full design, and ADRs.
- `templates/` — reusable thinking, design, PM, ADR, threat-model, and review templates.
- `portfolio/` — collected polished outputs for interview or career proof.
- `scripts/` — optional local helper scripts for creating session logs and weekly summaries.

## Core discipline

Use this system like a serious bootcamp:

- Write before asking for answers.
- Explain trade-offs in every design.
- Record mistakes honestly.
- Repeat weak areas until they become strengths.
- Build artifacts weekly.
- Review from multiple roles: PM, architect, security, DevOps, cost, and principal engineer.
