## 20 questions and frameworks top engineers use when designing systems:
**Clarify the problem first**

1. **What problem are we actually solving?** — Half of bad systems solve the wrong problem well.
2. **What happens if we do nothing?** — Tests whether the work is worth doing at all.
3. **Who are the users and what's the scale?** — 100 users vs 10M users are completely different designs.
4. **What are the non-negotiables vs nice-to-haves?** — Forces explicit prioritization of security/latency/cost.

**Design & trade-offs**

5. **What breaks first when load grows 10x? 100x?** — Reveals the real bottleneck before it happens.
6. **What's the simplest design that could possibly work?** — Start there; complexity must earn its place.
7. **What are we trading off?** — Every choice costs something (CAP theorem thinking: consistency vs availability). If you can't name the trade-off, you don't understand the design.
8. **Build vs buy vs open-source?** — Is this our core differentiator, or undifferentiated heavy lifting?
9. **One-way or two-way door?** (Bezos) — Reversible decisions should be fast; irreversible ones deserve deep analysis.
10. **What would this look like as boring technology?** — "Choose boring tech": innovation tokens are limited, spend them only where it matters.

**Failure & security**

11. **How does this fail, and what does the user see when it does?** — Design the failure mode, don't discover it.
12. **What's the blast radius?** — If this component dies or is breached, what else goes down?
13. **Pre-mortem: it's 6 months later and the project failed — why?** — Surfaces risks nobody wants to say out loud.
14. **What would an attacker do first?** — Think like the adversary, not the defender.
15. **Can we roll back in under 5 minutes?** — If not, deploys are gambling.

**Operations & evolution**

16. **How will we know it's broken before users tell us?** — Observability as a design requirement, not an afterthought.
17. **Can a new engineer understand and safely change this in their first month?** — Maintainability is a feature.
18. **What will we regret hardcoding a year from now?** — Identify axes of change; make those flexible, freeze the rest.
19. **What does this cost per user/request, and how does that curve bend at scale?** — Efficiency as unit economics.
20. **Five Whys** — When something fails, ask "why" repeatedly until you hit the systemic root cause, not the surface symptom.

- A meta-framework tying these together: top engineers loop through **understand → constrain → simplify → break it (mentally) → measure → iterate**.

---
## A a daily practice routine, question sets, and one core workflow you can apply to any project.

**Daily practice (60–90 min, compounding over years)**

- **Design one system on paper (20 min)**: Pick anything — Uber, a URL shortener, your company's product — and sketch the architecture, then ask "what breaks at 10x?" Do this daily and design intuition becomes reflex.
- **Read one real-world failure or design doc (15 min)**: Postmortems (Cloudflare, GitHub, AWS outage reports), engineering blogs, or RFCs from your own company. You learn more from one real failure than ten tutorials.
- **Write daily (10 min)**: One paragraph — a decision you made and *why*. Writing exposes fuzzy thinking. This becomes your personal decision journal.
- **Deliberate coding/practice (20–30 min)**: Not grinding random problems — pick a weakness (concurrency, SQL, networking) and drill it for 2–4 weeks before rotating.
- **Weekly review (30 min, once a week)**: Reread your decision journal. Which predictions were wrong? Why? This calibration loop is what actually builds judgment — most people skip it.

**The universal workflow when joining any project**

1. **Understand**: What problem, for whom, why now, what's success measured by?
2. **Map constraints**: Time, money, team skills, existing systems, non-negotiables.
3. **Generate 2–3 options**: Never one. If you only have one option, you haven't thought.
4. **Name the trade-offs out loud**: "Option A is faster to ship but locks us into X."
5. **Decide + write it down**: Decision, reasoning, what would change your mind.
6. **Set a checkpoint**: When will we revisit whether this was right?

**Questions to ask yourself**

- What do I believe here that I haven't verified?
- Am I solving the problem or the symptom?
- What would the best engineer I know ask right now?
- If this fails in 6 months, what will the cause have been? (pre-mortem)
- Am I confident because of evidence, or because I want to be done?

**Questions to ask customers**

- "Walk me through the last time you dealt with this problem" — stories, not opinions.
- "What are you doing today to work around it?" — real pain has existing workarounds.
- "If this disappeared tomorrow, what would you lose?" — measures actual value.
- "What have you tried that didn't work, and why?"

**Questions to ask coworkers**

- "What do you know about this system that isn't written down anywhere?"
- "What's the thing everyone's afraid to touch, and why?"
- "What would you do differently if you rebuilt this today?"
- "What am I missing?" — asked genuinely, at the end of every design discussion.

**On confidence**: it doesn't come from knowing everything — it comes from having a *process* you trust. If you can walk into any room and run understand → constrain → options → trade-offs → decide → checkpoint, you never need to fake certainty. Saying "I don't know yet, but here's how I'll find out" is what senior confidence actually sounds like.

The single highest-leverage habit in all of this is the decision journal plus weekly review. Skill comes from reps; judgment comes from reviewing your reps.
