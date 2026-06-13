---
name: cron-heartbeat-protocol
description: Detailed edge cases, scenarios, and decision trees for the hourly pipeline heartbeat cron.
version: 1.3.0
author: Andy
tags:
  - career
  - cron
  - heartbeat
  - pipeline-check
---

# Cron Heartbeat Protocol

The heartbeat cron (`74b1faef5bc3`) runs hourly Mon-Sun 7am-7pm PT. Its purpose is pipeline health surveillance — not discovery, not data hygiene, but early warning of things that need Maxime's attention.

## Scenario Decision Tree

### Scenario A: Interview is TODAY

**Example:** Intersect Power phone screen scheduled 2026-05-25.

1. Check if prep materials were already sent (look for interview-prep emails in SENT folder)
2. If prep sent → mark as handled, do not re-send
3. If prep NOT sent → escalate immediately (this is a pipeline failure)
4. If interview has passed but no debrief recorded → check if debrief was handled elsewhere; if not, add to report

**Heuristic:** If `interview_date == today` and prepped materials exist on file, heartbeat should [SILENT] on this item.

### Scenario A-B: `next_alert_date` passed but interview already completed

**Example:** Intersect Power phone screen passed 2026-05-25. Interview entry has `next_alert_date: 2026-05-26`. No new action needed — next steps (coordinating tech round prep) await Maxime's initiation.

**Protocol:**
1. Read the `interviews[]` array in job_leads.json for the lead
2. If the most recent interview has `outcome: "passed"` and `next_alert_date` is today or earlier:
   - Check if prep for the NEXT round has been requested or initiated
   - If Maxime hasn't initiated next-round prep → do NOT auto-prepare (let Maxime drive the pace)
   - Log in notes: `[heartbeat] next_alert_date triggered but awaiting Maxime to initiate next-round prep`
   - Do NOT flag in report — this is expected, not urgent
3. If the most recent interview has `outcome` that is NOT "passed" (e.g., `"cancelled"`, `"pending"`, `"rescheduled"`) → flag in report, potentially urgent
4. If there's no `outcome` field and `next_alert_date` is today → flag as "interview occurred but no outcome recorded"

**Rationale:** `next_alert_date` is a pacing reminder, not an escalation trigger. The heartbeat should only surface it if it signals something broken (no outcome recorded) or needs immediate action (interview cancelled). Otherwise, [SILENT] is correct.

### Scenario A-C: `next_update_date` triggered — past interview with no outcome recorded

**Example:** CAISO (lead-027) interview with Yu Wan on 2026-05-26, no outcome logged, `next_update_date: 2026-05-30`.

This scenario differs from Scenario A-B because `next_update_date` is a *scheduled check-in* field set when the interview date passes without a recorded outcome. Unlike `next_alert_date` (a pacing reminder that's safe to skip), `next_update_date` means "expected to have heard something by now" — it's a softer escalation signal.

**Decision tree:**
1. Did the interview date pass without an `outcome` field recorded?
   - YES → This is the trigger condition. Proceed to step 2.
   - NO → The interview has a recorded outcome. However, `next_update_date` may still be actionable if the outcome creates an expectation (e.g., "passed → resulting in offer" means a decision or next step was due). Do NOT skip — proceed to step 2 with adjusted framing.
2. Check email for employer replies from known contacts (coordinator, recruiter, hiring manager)
   - Reply found → Follow Scenario B (employer reply received)
   - No reply → Continue to step 3
3. Determine action based on outcome:
   - **If outcome is "passed" and the lead has an `offer` object with deadline** → cross-reference the deadline against today. If deadline has passed and lead status is terminal (offer_accepted/offer_declined), this may indicate a resolved decision. Check employment_status.json for consistency (see Scenario H). Do NOT flag the interview — flag the data integrity check.
   - **If outcome is "passed" without an `offer` object** → this is a Scenario A-B case (awaiting Maxime to initiate next round). [SILENT] is correct.
   - **If outcome is NOT "passed"** (e.g., "cancelled", "pending", "rescheduled") → flag in report, this signals something broken.
   - **If outcome is recorded but ambiguous** (e.g., "passed with concerns", outcome field present but notes are sparse) → best effort: does the lead show forward progress? If yes, treat like "passed". If unclear, flag for Maxime.
4. If recruiter/coordinator email is known and a follow-up is warranted → propose follow-up to that contact (confirmation required — cannot send autonomously per AGENTS.md email rules)
5. If no known contacts → flag in report with "No known contact to follow up with — Maxime may have the hiring manager's contact directly"
6. If this is the 2nd+ `next_update_date` cycle with no forward progress → escalate to "No progress after [N] days — needs Maxime's attention"
7. **`next_update_date` fired on terminal-status lead** — If the lead has reached a terminal status (`offer_accepted`, `offer_declined`, `hired`, `started`) and the offer deadline has passed, the `next_update_date` is stale data. The terminal status supersedes the pending check-in. Do NOT flag the interview or the missing outcome. Instead, proceed to Scenario H to check employment_status.json consistency.

**Key differences from `next_alert_date`:**
| Field | Purpose | Action on trigger |
|-------|---------|-------------------|
| `next_alert_date` | Pacing reminder — "it's been this long, check in" | Do NOT flag unless outcome missing; [SILENT] is correct |
| `next_update_date` | Scheduled check-in — "expected update by now" | Evaluate via decision tree above; may flag for data integrity check |

### Scenario B: Employer reply received

**Example:** Recruiter from Intersect Power emailed to reschedule/cancel.

1. Read the email content via `google_api.py gmail get <id>`
2. If it's a reschedule → update `interview.date` in job_leads.json, add note
3. If it's a rejection → DO NOT auto-update status (per URL health check violation rule). Flag in report for Maxime
4. If it's a request for more info → flag in report with "CONFIRMATION REQUIRED"
5. If it's an offer/progress update → flag in report for Maxime

### Scenario C: Daily digest already sent today

If the job hunt/digest ran earlier today (check `memory/weekly/YYYY-MM-DD_digest_thread.json`):

- Items in the digest are already on Maxime's radar
- Do NOT re-nudge the same items
- Only escalate if something NEW happened since the digest (email reply, status change)
- [SILENT] is the expected outcome for heartbeat runs that follow a digest

### Scenario D: Stale items, no digest today

If the last digest was >1 day ago and there are stale items:

- Stale items = `status: "stale"` in job_registry.json, or `last_verified` >14 days ago
- These need re-verification (but cannot do URL checks without shell/browser tools)
- Flag the count of stale items and suggest registry maintenance run
- Do NOT auto-close any — that's registry maintenance's job

### Scenario E: Active lead pending >5 days with score >= 3

**Example:** Offer #010 (City of Santa Clara, score=3) pending since 2026-04-08.

- This has been pending ~47 days — well past the >5 day threshold
- But the item was already surfaced in multiple prior digests
- Heartbeat should note it in a report only if it hasn't been surfaced recently
- Check if it appeared in the last digest thread. If yes, no re-nudge needed
- If NOT in recent digest and >30 days old → flag as "Cold lead — may need re-verification"

### Scenario F: No active leads and no activity

- Zero leads in job_leads.json
- No interviews scheduled
- No email replies
- → [SILENT] — this is the nominal quiet state

### Scenario G: Offer/decision deadline is TODAY

When a lead with `offer_received` status has an `offer.deadline` matching today:

1. **This is the highest-priority pipeline signal** — the decision window closes today
2. Check the lead notes for a recorded decision (accept/decline/extension-granted)
3. If no decision recorded → flag with "⚡ DEADLINE TODAY — needs decision"
4. If decision already recorded → [SILENT] (action already taken)
5. **Do NOT suppress** because "it was already reported yesterday" — the deadline day is when action is actually required, not the day-before reminder
6. If the same deadline has been flagged 3+ consecutive cron runs without action: note the repetition count in the report so Maxime sees the escalation history

### Scenario H: Employment status mismatch with terminal lead status

When a lead has reached a terminal/completed status (`offer_accepted`, `offer_declined`) and the offer deadline has passed, but `employment_status.json` still contains contradictory data (e.g., `"unemployed"` when a lead says `"offer_accepted"`):

This is a **data integrity signal**, not a pipeline escalation. The heartbeat should surface it because stale employment status corrupts downstream gates — the career_employment-optimizer blocks when `status: "unemployed"` and the weekly job hunt runs unnecessarily if already employed.

**Decision tree:**
1. Scan all leads in `job_leads.json` for terminal statuses (`offer_accepted`, `offer_declined`, `hired`, `started`)
2. Cross-reference against `employment_status.json`:
   - **Match** (e.g., lead says `offer_accepted` and employment says `employed`) → [SILENT] on this check (data is consistent)
   - **Mismatch** (e.g., lead says `offer_accepted` but employment says `unemployed`) → proceed to step 3
3. Check if the offer deadline has passed:
   - **Deadline NOT passed** → possible that acceptance is pending the deadline. Do NOT flag — the deadline hasn't arrived yet.
   - **Deadline passed** → the decision window has closed. Proceed to step 4.
4. Check lead notes and interview outcomes for evidence:
   - Notes explicitly state "accepted" or "signed" → flag as stale employment_status.json (suggest update)
   - Notes mention "asked for extension" or "negotiating" → flag as "ambiguous — offer status and employment data disagree. Needs Maxime's clarification."
   - No notes about acceptance outcome → flag as "lead shows terminal status but employment data not updated and no notes confirm the decision"
5. **Cross-reference with job_registry.json when leads data is ambiguous** — If the lead notes in `job_leads.json` conflict with or lack definitive records (e.g., "Asked for extension" vs a clear "accepted"), look up the corresponding registry entry via `source_offer_id`. Registry entries often carry more detail (`accepted_date`, `accepted_salary`, explicit `status: "accepted"`). The registry is generally more authoritative for historical record-keeping; the leads file tracks active pipeline state. If the two disagree → flag as `"Lead-XXX and registry #YYY disagree on acceptance status — needs reconciliation"`.
6. Output format (MAX 2 lines):
   - `Company — Role — status is [terminal_status] but employment says unemployed. Offer deadline was [date]. Needs confirmation.`
7. This scenario can also trigger on leads with an `offer.deadline` that has passed and `status: "offer_received"` (not yet accepted/declined). In that case, do NOT flag employment mismatch — flag the missing decision instead (see Scenario G).

**Caveat — employment_status.json is manually updated.** The heartbeat should never auto-update it. Flagging the mismatch prompts Maxime to fix the data. If the flag has been raised 3+ consecutive heartbeats without response, escalate with "Stale employment status flagged N times."

## Common False Positives (Do NOT escalate)

| Signal | Why it's a false positive | Correct action |
|--------|--------------------------|----------------|
| Stale items from prior hunt | Just surfaced in weekly digest | Already handled, [SILENT] |
| Interview prep already sent | Prep was sent same day or prior day | Already handled, no re-send |
| Google auth notification | Security notification, not employer reply | Ignore (note in audit if suspicious) |
| Single-day gap since last digest | Normal cadence, not stale | [SILENT] |

## Email Search Patterns

Check email for employer replies using these queries:

```python
# General inbox check since date
google_api.py gmail search "after:YYYY-MM-DD is:inbox"

# Check for specific company from active leads
google_api.py gmail search "intersect OR tonya OR <company> after:YYYY-MM-DD"

# Check for interview-related emails
google_api.py gmail search "interview OR recruiter OR application after:YYYY-MM-DD"
```

The career inbox (`maxime+hireme@baudette.fr`) should contain:
- SENT items (digests, prep emails Andy sends) — labeled SENT
- INBOX items (employer replies) — these are what we're looking for

If the inbox search returns empty, there are no employer replies to process.

## References

- Main procedure: `SKILL.md` → `## PIPELINE HEARTBEAT (Cron)`
- Email rules: `../AGENTS.md` → `## Email Rules`
- Handoff contracts: `references/HANDOFFS.md`
- Cron troubleshooting: `references/cron-troubleshooting.md`

## Tool Constraints (Cron Context)

### Background

The heartbeat cron cannot use `execute_code` with subprocess calls (blocked in cron mode — no user to approve shell commands). However, `terminal` IS available and can be used to run `google_api.py` gmail commands directly. The `execute_code` block means you cannot write a Python script that calls subprocess to invoke `google_api.py`, but you can call it directly via `terminal`.

This section documents the fallback pattern (using `session_search` to cross-reference previous reports) when `terminal` is unexpectedly unavailable.

### Workflow: session_search workaround for email gap

When you cannot run google_api.py to check email (e.g., terminal fails or is unavailable):

1. **Run session_search** to find the last heartbeat cron output. Search for recent cron sessions using topic keywords (e.g., `"CAISO offer"` or `"Intersect Power"` or `"heartbeat"`). The most recent one likely contains the same flagged items.

2. **Cross-reference the previous report** against current data files:
   - Read `job_leads.json` — check if any lead statuses changed since the report
   - Read `job_registry.json` — check for new stale items not in the report
   - Read `metrics.json` — check if the pipeline snapshot date advanced

3. **Determine if anything is new:**
   - Previous report flagged items X, Y, Z → data files still show the same → no change → `[SILENT]`
   - Previous report flagged X, but data now shows a status change (e.g., `interview_scheduled` → `offer_received`) → this is NEW, flag it
   - Previous report mentioned an upcoming deadline that is still in the future → already surfaced, don't repeat
   - **Deadline that was "tomorrow" and is now "today"** → this is an ESCALATION, not a repeat (see Scenario G)

4. **Caveat — missed external signals:** This workaround cannot detect employer emails that arrived after the last report. If a critical decision window is open (e.g., offer deadline today), note the gap in your determination reasoning. The hourly cadence means the missed signal will be caught at most ~1 hour later when the next heartbeat runs.

### When to report despite the gap

| Situation | Should you flag? | Rationale |
|-----------|-----------------|-----------|
| Deadline already reported yesterday (deadline is tomorrow+) | No — already surfaced, don't repeat | `[SILENT]` |
| Deadline is TODAY (previously reported yesterday) | **YES** — deadline day is the most actionable moment, escalate | Report |
| Deadline passed, no outcome recorded | **YES** — escalation signal | Report |
| Deadline is tomorrow or further out | No — already surfaced, don't repeat | `[SILENT]` |
| Status changed in data files since last report | Yes — detectable via file diff | Report |
| New stale items appeared in registry | Yes — detectable via file diff | Report |
| No known change, no deadline, no new items | No — nothing actionable | `[SILENT]` |
