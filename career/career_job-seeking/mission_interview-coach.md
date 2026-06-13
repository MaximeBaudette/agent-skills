# Mission: Interview Coach

**Trigger:** "prep me for interview at X" | interview_scheduled in job_leads.json | "debrief my X interview"

**Startup Check:**
1. Read memory/feedback/interview_coach_feedback.json (unapplied) -> apply in-memory.
2. Read memory/feedback/learned_prefs.md (active for interview_coach/all) -> apply.

**Procedure:**
1. Phase 1 (Context): Load job_leads.json, find lead entry with status==interview_scheduled and interviews array present. If none -> ask Maxime for company, role, JD URL, date, format, contact.
2. Phase 2 (Research): 3 web_searches for company (mission, tech stack, news). 4 for role (interview format, Glassdoor questions, engineering blog). Compile snapshot. Label sourced vs. inferred questions.
3. Phase 3 (STAR Stories): Retrieve profile per AGENTS.md. Map experience banks (FAST-DERMS, HIL/Opal-RT, PhD) to themes (leadership, collaboration, debugging, ambiguity). Generate 5-8 STAR+R stories. Check/update career/leads/interview-prep/story-bank.md.
4. Phase 4 (Question Bank): 7-10 technical questions (DER control, IEEE 1547, HIL, PMU, Python grid apps, MODELICA, SCADA, system design). Framework + Maxime hook per question. 5-7 behavioral mapped to stories. 5 smart questions tailored to company.
5. Phase 5 (Negotiation): Baseline 150k floor, 170k+ TC target. Research market comps via web_search. Write 3 counter scripts (low-ball, on-target, equity-heavy).
6. Phase 6 (Write): Save to career/leads/<company>_<role>_interview_prep.md. Structure: TL;DR, Role Snapshot, STAR Quick-Ref, Tech Questions, Behavioral, Smart Questions, Negotiation Cheat Sheet, Logistics.
7. Phase 7 (Debrief): Collect outcome from Maxime (passed/rejected/pending/offer). Update job_leads.json (add outcome to interviews[].outcome, update lead status, set last_action). Append feedback.

**STAR+R Format:** Situation (2-3 sentences) -> Task -> Action (concrete tech details, tools, scale) -> Result (quantified) -> Reflection (lesson learned, seniority signal).

**Output:** Prep document career/leads/<slug>_interview_prep.md, updated job_leads.json, feedback entry

**Edge Cases:**
- 0 interviews pending -> ask Maxime for full details.
- 2+ pending -> list and ask which to prep.
- Glassdoor/Blind no data -> label "[inferred from JD]", never fabricate sources.
- No strong story for a behavioral theme -> flag as gap.
- Profile unavailable -> use known experience banks (FAST-DERMS, HIL, PhD).
- Same weak area in 3+ debriefs -> escalate: offer to build deeper prep module.
