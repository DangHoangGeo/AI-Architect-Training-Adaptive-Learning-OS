# Weekly Flow

## Day 1 — Concept foundation
Learn the fundamental concept and explain it in your own words.
The AI checks `memory/weak_areas.md` first. If a weak area overlaps today's topic, a 5-minute warm-up exercise runs before the main lesson.

## Day 2 — Azure service mapping
Map the concept to Azure services and identify alternatives.
Explain why each service fits and name at least one rejected alternative with a trade-off.

## Day 3 — Design exercise
Create a small design and explain assumptions.

**Product framing (2 minutes before drawing any components):**
Write the following before starting the design:
1. The user's pain in one sentence.
2. The MVP constraint: what is the simplest version that proves value?
3. The metric that proves this worked (one number).

Only then begin the architecture design.

## Day 4 — Failure, security, and cost review
Stress-test the design through risk, cost, and operational questions.
Always apply the anti-shallow rule: 10x load, single point of failure, blast radius, cheapest version, enterprise compliance.

**Weeks 2, 3, 7, 9:** Run `/compare-cloud` after the design review.

**Weeks 10, 11, 12:** Run `/simulate-interview` — defend the previous workshop design as if presenting to a hiring panel.

## Day 5 — Communication and refinement
Improve the design and practice explaining it clearly.
Target audience: a non-technical executive or a new team member joining the project.
Must produce a 5-bullet executive summary that avoids implementation jargon.

## Day 6 — Weekly test
Take the weekly test. Passing threshold is 75/100.

Test format rotates:
- Weeks 1, 4, 7, 10: Standard 6-question written test
- Weeks 2, 5, 8, 11: Whiteboard challenge format
- Weeks 3, 6, 9, 12: Client brief format

## Day 7 — Workshop
Build the week's final artifacts and Bicep starter. Finish with review and reflection.

Required artifacts: `pm_brief.md`, `design.md`, `architecture_decisions.md`, `threat_model.md`, `main.bicep`, `modules/*.bicep`, `review.md`, `reflection.md`

Additional for Weeks 4, 5, 8: `cost_estimate.md`

After the workshop, run `/run-weekly-review` to surface skill progression, generate the portfolio entry, and decide whether to advance.
