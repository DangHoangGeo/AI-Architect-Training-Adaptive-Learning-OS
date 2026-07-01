# Week 12 Day 3 — Design exercise: AZ-305 Style Case Study and Decision Defense

## Goal
Complete a full AZ-305-style case study under timed conditions, then write the "decision defense" section of your portfolio — the section that demonstrates you can defend your architectural choices under adversarial questioning from a panel that includes an engineer, a security specialist, and a finance director. This section is the hardest to write and the most valuable in an interview.

## Why this matters
AZ-305 is structured around case studies: a scenario is given, constraints are listed, and you must select the correct Azure service and configuration for each requirement. The exam rewards the same thinking process you have been training for 11 weeks — business requirement first, constraints second, service selection with justification third. More importantly, real architect interviews use the same format — "given this scenario, what would you do and why?" If you cannot work through a complex scenario systematically under time pressure, you will fail both the exam and the interview.

## Product framing (write this first)
> **User pain:** Candidates who have studied Azure services individually often fail AZ-305 because they cannot apply multiple concepts simultaneously in an unfamiliar scenario — they recognize the services but cannot make the decision under pressure.
> **MVP constraint:** You have 45 minutes to read a scenario, identify the requirements, map them to Azure services, and write a justified recommendation. This mirrors the AZ-305 case study time pressure.
> **Success metric:** Your written answer scores at least 80% against the rubric below within the 45-minute time limit.

## Case study: GlobalCare Health Network

**Company overview:** GlobalCare is a private healthcare network operating 12 hospitals and 60 clinics across the UK and Netherlands. They process 2 million patient records and 15,000 clinical transactions per day. They are migrating from on-premises to Azure over 18 months.

**Current state:** On-premises SQL Server 2016 (500GB patient database), VMware VMs running an EMR (Electronic Medical Records) application, file shares for medical imaging (8TB DICOM files), and a custom-built patient portal (ASP.NET 4.8).

**Requirements:**
- R1: Patient data must remain in EU regions only (UK South or West Europe). No data may be processed outside the EU.
- R2: The EMR application must achieve RTO = 4 hours and RPO = 1 hour for a full regional failure. This is a regulatory requirement under NHS Digital guidelines.
- R3: Medical imaging files must be accessible within 200ms for radiologists and within 5 seconds for archival queries.
- R4: The patient portal must support 50,000 concurrent users during peak visiting hours (7pm-9pm).
- R5: All patient data must be encrypted with customer-managed keys. The encryption key must be stored in a location separate from the encrypted data.
- R6: The migration must be completed with zero data loss and maximum 4 hours of planned downtime for the database migration.
- R7: Within 12 months of migration, the IT team (6 engineers, no cloud expertise today) must be able to operate the platform without external consultants.

**Your answer must include (rubric):**
- For each of the 7 requirements: the Azure service(s) that satisfy it, the specific tier/configuration, and one sentence explaining why this service satisfies this requirement (worth 10 points each).
- One requirement where you see a conflict between two requirements, and how you resolve it (worth 20 points).
- One risk that is not mentioned in the requirements but will affect the migration (worth 10 points).

## Decision defense section (write after the case study)

After completing the case study, write the "decision defense" section of your portfolio. Choose one decision from your Week 9, 10, or 11 work that you know is controversial or imperfect — one that a smart interviewer would challenge. Write a 250-word "pre-emptive defense" that:
- Names the decision and the alternative.
- Explains the constraint that made the alternative impractical.
- Acknowledges the weakness of your chosen approach.
- States the condition under which you would change the decision.

## Learn — write notes answering these

- What is the AZ-305 exam's scoring approach for case study questions — is partial credit awarded, and how does this change your answering strategy when you are uncertain?
- How do you identify a "hidden conflict" in a requirements list — a situation where satisfying R1 makes it harder to satisfy R4?
- What is the difference between Azure Blob Storage "Hot," "Cool," "Cold," and "Archive" tiers, and which is correct for each of GlobalCare's medical imaging access patterns?
- What Azure service enables a 6-person team with no cloud expertise to manage infrastructure changes with guardrails, approvals, and rollback — without writing Bicep from scratch?

## Micro exercise

Complete the GlobalCare case study and the decision defense section as described above. Write your Product framing first, then the case study answer, then the decision defense. Set a 45-minute timer for the case study portion — time discipline is part of the exercise.

## Reflection question
You scored yourself against the rubric after completing the case study. Which two requirements were hardest, and why? Is the difficulty due to not knowing the Azure service (a knowledge gap), or not knowing how to apply it to the specific constraint (a judgment gap)? The answer determines what you study in the remaining 2 days.

## Prior concept connection
R2 (RTO/RPO for the EMR application) is directly covered by your NovaPay work from Week 11. R1 (data residency) and R5 (customer-managed keys) connect to your LexAI work from Week 9. R4 (50,000 concurrent users) connects to your PeopleOS scalability work from Week 10. Before writing your answers, explicitly reference which week's learning informed your decision for each requirement.

## AI coach instructions
The learner must write the Product framing before starting the case study. Do not help with the case study during the 45-minute window — only evaluate afterward. Score the answer against the rubric (70 points for 7 requirements × 10, 20 points for conflict resolution, 10 points for hidden risk = 100 total). A score below 70 means the learner needs targeted review. Watch for: (1) the learner not referencing prior weeks' learning in the case study, (2) the decision defense that acknowledges only trivial weaknesses, (3) a reflection that identifies only knowledge gaps (judgment gaps are more important to name). Probe the decision defense: "You said you would change this decision under condition X. Has condition X already been met in your existing designs? Why did you not change it there?" Update `memory/weak_areas.md` with the two hardest case study requirements and the score. Update `memory/progress.md` with Week 12 Day 3 progress.

## Completion criteria
- Learner wrote Product framing before starting.
- Learner completed the GlobalCare case study within 45 minutes with answers for all 7 requirements.
- Learner identified at least one requirement conflict.
- Learner identified at least one unlisted migration risk.
- Learner wrote a 250-word decision defense for a controversial prior design choice.
- AI scored the case study and recorded the result in `memory/progress.md`.
- Any mistakes added to `memory/mistakes.md`.
