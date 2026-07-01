# Session Commands

## Daily

### `/start-training`
Start the correct daily lesson based on memory and roadmap.
On first session: runs diagnostic test, detects persona, sets baseline.

### `/check-understanding`
Ask three questions: one definition, one scenario, one trade-off.

### `/review-my-answer`
Review the learner's answer using the current skill lens and scoring rubric.

### `/end-session`
Write the session recap and memory updates.

## Weekly

### `/run-weekly-test`
Use the current week's test file. Score strictly. Passing threshold is 75/100.
- Odd weeks (W3, W5, W7, W9, W11): Use whiteboard challenge format (`tests/whiteboard-challenge-template.md`).
- Weeks 3, 6, 9, 12: Use client brief format (`tests/client-brief-template.md`).
- All other weeks: Use standard 6-question written format.

### `/start-workshop`
Start the current week's workshop only if the test is passed. If not passed, generate a recovery plan.

### `/run-weekly-review`
Review all progress, logs, test score, and workshop artifacts. Decide advance/repeat/recovery.
Surfaces skill matrix progression, generates portfolio entry, and states what next level requires.

## Review

### `/review-design`
Use cloud architect, product manager, security architect, DevOps engineer, and cost optimizer views.

### `/review-bicep`
Check naming, parameters, security defaults, modularity, idempotency, outputs, environment support, and deployment risks.

### `/simulate-interview`
Use `.skills/interviewer.md` and ask scenario-based questions.
Mandatory on Day 4 of Weeks 10, 11, and 12. Scores communication, trade-off awareness, technical accuracy.

## Analysis commands

### `/compare-cloud`
Compare the current design to its AWS and GCP equivalent.
For each major service in the design:
- Name the AWS/GCP equivalent service.
- State what you would gain by choosing it.
- State what you would lose.
- Identify vendor lock-in risk in the current Azure design.
- State when Azure is genuinely better vs. a preference choice.

Activate this automatically on weeks 2 (networking), 3 (identity), 7 (security), and 9 (AI systems) after the design exercise.

### `/estimate-cost`
Produce a rough monthly cost estimate for the current design at both dev and prod scale.
Format:
- Top 3 cost drivers with estimated monthly range (e.g., "Azure SQL: $150–300/month prod").
- Total rough estimate range (dev / prod).
- One change that would reduce cost by ~30% and its trade-off.
- Update `memory/cost_estimates.md` with the result.

Required artifact for Weeks 4, 5, and 8 workshops.

## Role switching

`/switch-role <role>` loads a file from `.skills/` and applies that role's review behavior.

Available roles:
- `cloud-architect`
- `product-manager`
- `security-architect`
- `devops-engineer`
- `ai-engineer`
- `cost-optimizer`
- `principal-engineer`
- `interviewer`
- `az305-exam-coach`
- `multi-cloud-comparator`
