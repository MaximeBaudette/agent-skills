# SELF_IMPROVE — Self-Improvement Protocol

**Skill:** `career_job-seeking`
**Version:** 1.0.0

---

## Overview

Every mission in the career_job-seeking skill continuously learns from feedback. Andy collects ratings and freeform notes at the end of each run, accumulates them in per-mission feedback files, applies them in-memory on subsequent runs, and escalates to Maxime when a pattern becomes strong enough to warrant a permanent change.

The key invariant: **Andy never permanently modifies mission documentation without explicit approval from Maxime.** In-memory tuning is fine; persistent changes require a human decision.

---

## How It Works

```
END OF MISSION RUN
       │
       ▼
Andy prompts for feedback:
"Rate this run 1-5 or give feedback: `feedback: [rating] [notes]`"
       │
       ▼ (Maxime provides feedback)
Andy parses feedback → appends entry to feedback file with applied: false
       │
       ▼
NEXT MISSION RUN STARTUP
       │
Read feedback file → find entries where applied: false
Apply tuning in-memory (do NOT modify file at startup)
       │
At end of run → mark applied: true for each processed entry
       │
       ▼
COUNT CHECK: same aspect appears 3+ times across entries
       │
       ▼ (threshold reached)
Escalation: ask Maxime whether to update mission definition permanently
       │
If Maxime says "confirm update: yes" → update mission doc
If Maxime says no or ignores → continue applying in-memory only
```

---

## Feedback Files

One per mission:

| Mission | Feedback File |
|---|---|
| Job Hunt | `memory/feedback/job_hunt_feedback.json` |
| Lead Tracking | `memory/feedback/lead_tracking_feedback.json` |
| Interview Coach | `memory/feedback/interview_coach_feedback.json` |

Cross-mission preferences:

| File | Purpose |
|---|---|
| `memory/feedback/learned_prefs.md` | Persistent preferences applicable across missions |

---

## Per-Mission Feedback Entry Schema

```json
{
  "date": "YYYY-MM-DD",
  "aspect": "<aspect tag>",
  "rating": 4,
  "note": "freeform text describing what to do differently",
  "related_ids": ["042"],
  "applied": false
}
```

### Field Definitions

| Field | Type | Required | Description |
|---|---|---|---|
| `date` | string | yes | ISO date of the feedback |
| `aspect` | string | yes | Categorical tag (see valid values per mission below) |
| `rating` | integer or null | no | 1-5 overall run rating; null if feedback-only, no rating |
| `note` | string | yes | What to change or improve |
| `related_ids` | array | no | Offer IDs (registry_id) this feedback relates to; empty array if general |
| `applied` | boolean | yes | false = pending; true = applied in a subsequent run |

### Valid `aspect` Tags

**Job Hunt:**
- `scoring` — scoring rubric calibration (over/under-scoring)
- `queries` — search query construction (too broad, too narrow, missing keywords)
- `email_format` — digest email structure or content
- `phase_skipped` — a phase was incorrectly skipped
- `dedup` — registry deduplication issue
- `reply_parsing` — parsing of SCORES/FEEDBACK reply
- `other`

**Lead Tracking:**
- `pipeline_update` — status update process
- `application_package` — cover letter or CV tailoring quality
- `follow_up` — follow-up email timing or content
- `status_transitions` — incorrect transition or missing transition
- `ingestion` — handoff ingestion issue
- `other`

**Interview Coach:**
- `star_stories` — story selection or quality
- `question_bank` — wrong questions, missing areas, wrong difficulty level
- `negotiation_prep` — negotiation numbers or scripts
- `research_depth` — company or role research quality
- `debrief` — debrief process or recording
- `other`

---

## Learned Preferences Schema

`memory/feedback/learned_prefs.md` — cross-mission persistent preferences.

```json
{
  "schema_version": "1.0",
  "prefs": [
    {
      "pref_id": "pref_001",
      "mission": "job_hunt",
      "aspect": "scoring",
      "description": "Always include a note about why a score >= 8 was assigned",
      "source": "escalated_feedback",
      "confirmation_count": 3,
      "active": true,
      "created_date": "YYYY-MM-DD",
      "last_confirmed": "YYYY-MM-DD"
    }
  ]
}
```

### Field Definitions

| Field | Type | Description |
|---|---|---|
| `pref_id` | string | Unique ID: `pref_NNN` (zero-padded) |
| `mission` | string | `"job_hunt"`, `"lead_tracking"`, `"interview_coach"`, or `"all"` |
| `aspect` | string | Same aspect tags as feedback entries |
| `description` | string | What the preference dictates Andy should do |
| `source` | string | `"escalated_feedback"` (from 3+ count) or `"explicit"` (Maxime said directly) |
| `confirmation_count` | integer | Number of times this preference was reinforced before promotion |
| `active` | boolean | true = apply this preference; false = retired |
| `created_date` | string | ISO date promoted to learned pref |
| `last_confirmed` | string | ISO date last reinforced |

---

## Promotion Rule (3+ Confirmations → Escalation)

When reviewing feedback entries at the start of a run:

1. Count entries per `aspect` where `applied: false` (pending)
2. Also count recent `applied: true` entries on the same aspect (past 90 days)
3. If same `aspect` has **3 or more entries total** (pending + recently applied) → escalation

**Escalation message to Maxime:**
```
I've noticed repeated feedback on [aspect] in the [mission] mission:

- "[note from entry 1]" (YYYY-MM-DD)
- "[note from entry 2]" (YYYY-MM-DD)
- "[note from entry 3]" (YYYY-MM-DD)

Should I update the [mission] behavior permanently to reflect this?
Reply "confirm update: yes" to make it permanent, or "no" to keep applying it in-memory only.
```

**On "confirm update: yes":**
1. Write new entry to `learned_prefs.md` with `source: "escalated_feedback"`
2. Mark all related feedback entries `applied: true`
3. Apply the preference from that run forward

**On "no" or no response:**
- Mark entries `applied: true` after applying them this run
- Continue applying in-memory on future runs (will re-count from new feedback)

---

## Escalation Protocol

**What can be permanently updated:**
- How Andy constructs search queries (scoring weights, keyword lists)
- Which aspects of the cover letter template to emphasize
- Digest email formatting preferences
- Staleness thresholds
- Any behavioral default in a mission

**What requires Maxime's manual edit (Andy never touches these):**
- SKILL.md mission documentation
- Mission spec sub-docs (`mission_*.md`)
- HANDOFFS.md schemas
- This file (SELF_IMPROVE.md)

Even on "confirm update: yes", Andy only updates `learned_prefs.md` — not the mission docs themselves. If the change is significant enough to warrant a doc update, Andy drafts the change and asks Maxime to review and apply it.

---

## How Andy Prompts for Feedback

At the **end of every mission run**, Andy always says:

> "Rate this run 1-5 or give feedback: `feedback: [rating] [notes]`"

**Examples:**
```
feedback: 4 queries were good but tier 3 had too many irrelevant results
feedback: 3 the cover letter was too generic, didn't reference their specific SCADA stack
feedback: 5 perfect
feedback: negotiation numbers were too low, I target 180k not 170k
```

---

## Parsing Rules

### Parsing `feedback: [rating] [notes]`

1. Match pattern: starts with `feedback:` (case-insensitive, colon required)
2. Next token after `feedback:`: if it's an integer 1-5 → `rating`; otherwise rating = null
3. Remainder of the line (after rating if present) → `note`
4. If `note` mentions specific offer IDs like `#042` → add to `related_ids`
5. Infer `aspect` from note content:
   - mentions "score", "scoring", "8/10", "7/10" → aspect = "scoring"
   - mentions "query", "queries", "search", "results" → aspect = "queries"
   - mentions "email", "digest", "format" → aspect = "email_format"
   - mentions "cover letter", "application", "CV" → aspect = "application_package"
   - mentions "STAR", "story", "interview prep" → aspect = "star_stories"
   - default → aspect = "other"

### Parsing free-form feedback (no `feedback:` prefix)

If Maxime says something like "your scoring is too generous" during or after a run, Andy should:
1. Recognize this as implicit feedback
2. Append to feedback file with the inferred aspect
3. Respond: "Got it — I'll calibrate scoring more conservatively starting next run."

### Parsing "confirm update: yes"

1. Find the pending escalation context (held in memory during the session)
2. Write to `learned_prefs.md`
3. Acknowledge: "Preference saved. I'll apply [description] in all future [mission] runs."

---

## Feedback File Initialization

If a feedback file doesn't exist when Andy tries to read it at startup → treat as empty (no feedback to apply). Do NOT create the file at startup. Create it only when writing the first feedback entry.

---

## Interview Coach Special Rule

If the same `weak_moment` topic appears in 3+ debrief entries across different interviews:
- Escalate with: "I've noticed you've felt underprepared on [topic] in 3+ interviews. Want me to build a deeper prep module for it?"
- This is separate from the 3+ feedback count rule — it operates on debrief data directly

---

## Applied Flag Semantics

- `applied: false` → Andy has not yet applied this feedback to any run
- `applied: true` → Andy has processed this feedback entry in at least one run

Andy marks entries `applied: true` at the END of the run where they were processed (not at startup). This ensures the feedback is actually acted on before being marked done.

Multiple feedback entries with the same aspect can accumulate before all being applied; apply all pending ones together each run.
