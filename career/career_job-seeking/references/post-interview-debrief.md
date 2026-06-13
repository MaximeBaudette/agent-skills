# Post-Interview Debrief Documentation

**Created:** 2026-05-25

## When to Use

After every interview (screen, technical round, take-home, or final). Capture notes within 1 hour while memory is fresh.

## What to Capture

### 1. Outcome
- Passed / Rejected / Pending / Offer
- Gut feel: how well did Maxime think it went?

### 2. Company Intel
- Team structure and geography
- Role logistics (travel, remote, hours)
- Interview process (next steps, timeline, format)
- Cultural signals

### 3. Compensation Intel
- Base salary discussed
- Bonus structure and targets
- Equity/stock type and vesting
- Benefits (401k, insurance, stipends, PTO)
- Compare to posted JD range — flag discrepancies
- Save to memory/salary_research.json

### 4. What Went Well
- Topics Maxime handled confidently
- Questions that landed well

### 5. Lessons for Next Time
- Areas to strengthen
- Questions that caught Maxime off guard
- Prep gaps identified

## Output

Create interview-debrief.md in the lead directory:
career/leads/<YYYY-MM>-<company>-<role>/interview-debrief.md

## Updating the Pipeline

1. **job_leads.json**: Add outcome to interviews[].outcome, update notes with debrief intel
2. **handoffs/lead_to_interview.json**: Update `interview_outcome` field to match (e.g. `"passed_to_next_round"`, `"rejected"`, `"pending"`). This file is the canonical handoff to Interview Coach — leaving it `null` after a recorded outcome creates a stale-handoff warning.
3. **job_registry.json**: Update notes with comp details + status changes
4. **salary_research.json**: Add comp data point for future negotiation reference
5. **KB**: Submit durable interview insights to KB for MARS archiving
