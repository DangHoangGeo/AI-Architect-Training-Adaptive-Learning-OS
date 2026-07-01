# Operating Rules

## Advancement rules

- Daily lesson completion requires a written answer and AI feedback.
- Weekly test passing threshold: 75/100.
- Workshop unlock requires weekly test pass.
- Weekly completion requires workshop artifacts and review.
- Two failed weeks in a row trigger a recovery week.

## Scoring rules

Use evidence from the learner's written work. Do not score based on confidence or intention.

## Workshop artifact rule

Every workshop must produce:

- `pm_brief.md`
- `design.md`
- `architecture_decisions.md`
- `threat_model.md`
- `main.bicep`
- `modules/*.bicep`
- `review.md`
- `reflection.md`

Weeks 4, 5, and 8 additionally require:

- `cost_estimate.md` — rough monthly cost at dev and prod scale, top 3 cost drivers, one 30%-reduction option with trade-off

## Anti-shallow rule

When the learner proposes a design, always ask:

1. What breaks at 10x load?
2. What is the single point of failure?
3. What is the blast radius if compromised?
4. What is the cheapest acceptable version?
5. What would you change for enterprise compliance?

## Weekly test format rotation

Do not use the same test format every week. Rotate as follows:

| Week | Test Format |
|---|---|
| 1, 4, 7, 10 | Standard 6-question written test |
| 2, 5, 8, 11 | Whiteboard challenge — draw architecture, explain it, answer 3 adversarial questions |
| 3, 6, 9, 12 | Client brief — receive a stakeholder email with requirements, produce an architecture proposal |

Use `tests/whiteboard-challenge-template.md` and `tests/client-brief-template.md` for the alternative formats.

## Interview simulation rule

Weeks 10, 11, and 12 include a mandatory interview simulation on Day 4:
- Load `.skills/interviewer.md`.
- Learner defends their previous workshop design as if presenting to a hiring panel.
- Score on: technical accuracy, trade-off awareness, communication clarity.
- Strong performance → update `memory/achievements.md`.
- Weak performance → record gaps in `memory/weak_areas.md`.

## Multi-cloud comparison rule

After every design exercise in Weeks 2, 3, 7, and 9, automatically invoke `/compare-cloud`.
Do not skip this step even if the learner does not request it.

## Portfolio population rule

After every `/run-weekly-review`, produce:
- `portfolio/week-XX-[name]/executive_summary.md` — 3 bullet points from pm_brief.md + design.md
- `portfolio/week-XX-[name]/key_decisions.md` — top 3 ADRs from architecture_decisions.md
- Instruct the learner to copy `design.md` into the portfolio folder

## Bicep complexity progression

Bicep scaffolds must increase in complexity across the 12 weeks:

| Weeks | Complexity Tier |
|---|---|
| 1–2 | Basic resource creation, environment parameter, `@description` decorators |
| 3–4 | Parameterized modules, `allowedValues`, `@minLength`/`@maxLength`, output wiring |
| 5–6 | Module outputs wired as inputs to downstream modules, environment conditionals (`if env == 'prod'`) |
| 7–8 | Private endpoints, `roleAssignments`, managed identity wiring, policy conditions |
| 9–10 | `existing` resource references, deployment scripts, user-assigned managed identity, `targetScope = 'resourceGroup'` |
| 11–12 | `targetScope = 'subscription'`, cross-region outputs, deployment validation pipeline, drift detection comments |

Week 8 scaffolds must demonstrate full modular library pattern. Week 12 must demonstrate multi-region parameterization.

## Persona adaptation rule

Read `memory/persona.md` at every session start. Adapt:
- Depth of service explanations (skip basics for senior profiles)
- Scaffolding level (add more for junior or PM-transitioning profiles)
- Emphasis (push cost/ops for infra backgrounds; push product framing for dev backgrounds)

If `memory/persona.md` does not exist, create it after the first session.
