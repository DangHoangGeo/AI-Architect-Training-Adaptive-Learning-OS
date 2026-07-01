# Memory Protocol

The memory folder is the persistent brain of the learning OS. It prevents the AI from behaving like a random tutor.

## Files to read at session start

- `memory/profile.md`
- `memory/progress.md`
- `memory/persona.md`
- `memory/mistakes.md`
- `memory/weak_areas.md`
- `memory/cost_estimates.md`
- `memory/decisions.md`
- Latest three files in `memory/session_logs/`

## Files to update during or after sessions

### `memory/progress.md`
Update when the learner completes a lesson, passes a test, completes a workshop, or repeats a week.

### `memory/persona.md`
- Create after the diagnostic test with archetype, baseline scores, strengths, gaps, acceleration candidates, deep-dive candidates, and coaching style.
- Update if the learner's pattern changes over 3+ sessions (e.g., a "junior developer" archetype showing senior-level performance consistently).

### `memory/mistakes.md`
Add concrete mistakes. Do not write vague statements like "needs improvement." Write specific observations:

```md
- 2026-07-01 — Week 02 Networking — Confused NSG filtering with Azure Firewall centralized inspection. Needs review of network security layers.
```

### `memory/weak_areas.md`
Update only when a pattern appears across at least two exercises, tests, or reviews.

### `memory/cost_estimates.md`
Add an entry after every `/estimate-cost` command and after every workshop that requires `cost_estimate.md`.
Include: date, week, services, SKUs, monthly ranges, top 3 cost drivers, one reduction option.

### `memory/decisions.md`
Record key architecture decisions from workshops using ADR style.

### `memory/session_logs/YYYY-MM-DD.md`
Create one log per session with:

- Topic
- Exercise
- Learner answer summary
- Feedback
- Score
- Mistakes
- Next action

## Recurring mistake rule

If the same mistake appears three times:

1. Mark it as `Recurring` in `memory/mistakes.md`.
2. Add it to `memory/weak_areas.md`.
3. Create a targeted recovery exercise before allowing the next workshop.

## Weak area activation rule

When reading `memory/weak_areas.md` at session start:
- If any weak area overlaps the current week's topic → deliver a 5-minute warm-up exercise before the main lesson.
- If a weak area is marked `Recurring` → offer a targeted recovery micro-exercise instead of the main lesson.

## Achievement surfacing rule

At every `/run-weekly-review`:
- State explicitly which skills advanced on the skill matrix with old → new score.
- Explain what the new level means in practice.
- State what the next level requires and which upcoming week develops it.
- Do not just write to `memory/achievements.md` silently — state the achievement out loud.

## Memory safety rule

Do not record private secrets, credentials, tokens, confidential customer data, or personal sensitive information.
