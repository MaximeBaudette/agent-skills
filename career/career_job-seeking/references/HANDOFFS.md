# HANDOFFS — Inter-Mission Data Contracts

**Skill:** `career_job-seeking`
**Version:** 1.1 (post two-registry split)

**Current architecture (authoritative):** See the DATA FLOW diagram and mission specs in `SKILL.md` + the individual `mission_*.md` files. Interviews are stored **inline** as an `interviews: [...]` array on entries inside `job_leads.json`. The ingestion handoff bridge between Job Hunt and Lead Tracking uses two files: `memory/handoffs/job_hunt_flagged_pending.json` (Phase 4 audit snapshot, read by Lead Tracking Phase 1 — see references/handoff-pending-contract.md for the actual schema) and `memory/handoffs/job_hunt_flagged.json` (Phase 6 post-reply output, documented below as Handoff File 1).

This document is **partially legacy**. It is retained for audit/historical reference but the live procedures and schemas in the active mission files + SKILL.md + `references/cross-file-consistency.md` take precedence. 

**Do not** use the legacy `lead_to_interview.json` sections below for current execution logic.

---

## Data Flow Overview (Current — see SKILL.md for the live diagram)

```
Job Hunt (discovery + scoring)  ──▸  job_registry.json
                                       │ (high-score flagged)
                                       ▼
                               memory/handoffs/job_hunt_flagged.json
                                       │
                                       ▼
Lead Tracking  ──ingest flagged──▸  job_leads.json   ◄── Registry Maintenance
  (Phases 1-9, inline updates)         │ (interviews[] embedded on lead entries)
                                       │ (status transitions, notes, collateral)
                                       ▼
Interview Coach  ──reads from job_leads──▸  per-lead prep docs + debriefs
                                       │
                                       ▼
                               memory/metrics.json + feedback/
```

**Key current contracts (post andy-improvement-plan two-registry migration):**
- Primary ingestion handoff: `memory/handoffs/job_hunt_flagged_pending.json` (Phase 4 audit snapshot → Lead Tracking Phase 1). See references/handoff-pending-contract.md for actual schema.
- Active pursuits + interview details live in `job_leads.json` (interviews stored inline as array on the lead object; no separate handoff file for new interviews).
- Lead Tracking Phase 5 now embeds `interviews` directly into the matching `job_leads.json` entry when status moves to `interview_scheduled`.
- Interview Coach reads the `interviews` array from the relevant lead(s) in `job_leads.json` (status==interview_scheduled and interviews present).
- Cross-file sync rules between `job_registry.json` and `job_leads.json` are in `references/cross-file-consistency.md`.
- See `mission_lead-tracking.md` (especially Phases 1,2,5,6) and `mission_interview-coach.md` for exact read/write rules.

Legacy `lead_to_interview.json` and old `application_pipeline.json` are no longer used by the active missions.

**Base path for all files:** `/home/mars/.hermes/profiles/career-manager/workspace/`

---

## Handoff File 1: job_hunt_flagged.json (Phase 6 post-reply)

**Written by:** Job Hunt Phase 6 (reply processing — after Maxime scores entries)
**Read by:** Lead Tracking Phase 1 (future — currently Phase 1 reads `job_hunt_flagged_pending.json` per references/handoff-pending-contract.md)

**Path:** `memory/handoffs/job_hunt_flagged.json`

### Schema

```json
{
  "schema_version": "1.0",
  "generated_date": "YYYY-MM-DD",
  "entries": [
    {
      "registry_id": "042",
      "title": "Senior Grid Engineer",
      "company": "ACME Corp",
      "location": "Oakland, CA",
      "tier": 1,
      "url": "https://example.com/job/123",
      "salary_range": "$140k-$180k",
      "maxime_score": 4,
      "ingested": false
    }
  ]
}
```

### Field Definitions

| Field | Type | Description |
|---|---|---|
| `schema_version` | string | Always `"1.0"` |
| `generated_date` | string | ISO date of the reply processing run |
| `entries[].registry_id` | string | Zero-padded 3-digit ID from job_registry.json |
| `entries[].title` | string | Job title |
| `entries[].company` | string | Company name |
| `entries[].location` | string | Location string |
| `entries[].tier` | integer | 1 = Oakland/Remote, 2 = Bay Area, 3 = Relocation |
| `entries[].url` | string | Direct URL to job posting |
| `entries[].salary_range` | string | Salary range or "Not disclosed" |
| `entries[].maxime_score` | integer | Maxime's score 1-5 (never 0 or -1 in this file) |
| `entries[].ingested` | boolean or "stale" | false = pending ingestion; true = ingested; "stale" = expired |

### Lifecycle Rules

1. Job Hunt Phase 6 writes/overwrites this file on each reply processing run
2. Lead Tracking Phase 1 reads it, adds entries to pipeline, marks each `ingested: true`
3. If Lead Tracking reads an entry where `ingested: false` and `generated_date` > 14 days ago → set `ingested: "stale"`, log to `memory/logs/handoff_warnings.log`
4. Lead Tracking writes the updated file back (with ingested flags updated)

### Staleness Rule

```
if entry.ingested == false AND (today - generated_date) > 14 days:
  entry.ingested = "stale"
  log: "STALE_HANDOFF: job_hunt_flagged.json entry #<registry_id> not ingested after 14 days"
```

---

## Handoff File 2: job_hunt_flagged_pending.json

**Written by:** Job Hunt Phase 4 (immediately after digest send)
**Read by:** Reference only — not consumed by any mission

**Path:** `memory/handoffs/job_hunt_flagged_pending.json`

**Purpose:** Snapshot of all surfaced unreviewed offers at digest-send time. Used as an audit trail and for reference if something goes wrong in reply processing.

### Schema (same structure as job_hunt_flagged.json but with match_score instead of maxime_score)

```json
{
  "schema_version": "1.0",
  "generated_date": "YYYY-MM-DD",
  "digest_sent_to": "maxime+hireme@baudette.fr",
  "entries": [
    {
      "registry_id": "042",
      "title": "Senior Grid Engineer",
      "company": "ACME Corp",
      "location": "Oakland, CA",
      "tier": 1,
      "url": "https://...",
      "salary_range": "$140k-$180k",
      "match_score": 8
    }
  ]
}
```

---

## Handoff File 3: lead_to_interview.json (LEGACY / DEPRECATED)

**Status:** No longer used by active missions after the two-registry + inline interviews migration (see andy-improvement-plan.md and current `mission_lead-tracking.md` Phase 5 + `mission_interview-coach.md`).

**Historical note (for audit only):** Previously, Lead Tracking Phase 5 wrote a separate `memory/handoffs/lead_to_interview.json`, and Interview Coach read from it. 

**Current behavior (use this instead):**
- Interview scheduling details are embedded directly as an `interviews: [ {date, round, interviewer, outcome, next_alert_date?, ...}, ... ]` array **on the lead object inside `job_leads.json`**.
- Lead Tracking updates the lead entry in `job_leads.json` (and syncs relevant fields back to the matching registry entry per cross-file-consistency rules).
- Interview Coach locates the lead(s) with `status == "interview_scheduled"` and a non-empty `interviews` array, then operates on the pending interview objects in place.
- Debriefs and outcomes are written back into the same inline `interviews` array on the lead (plus per-lead docs under `career/leads/.../`).

If you encounter an old `lead_to_interview.json` during cleanup or recovery, treat it as historical only and migrate relevant pending interviews into the corresponding `job_leads.json` entries.

**Do not** create or write to `lead_to_interview.json` in new runs. The mission specs are the binding contract.
---

## Shared Artifact: job_registry.json

**Written by:** Job Hunt (discovery + reply processing)
**Read by:** Lead Tracking (for queries, status updates), Interview Coach (for context), Job Hunt (for dedup)

**Path:** `memory/job_registry.json`

### Schema

```json
{
  "schema_version": "1.1",
  "last_id": 42,
  "offers": [
    {
      "id": "042",
      "title": "Senior Grid Engineer",
      "company": "ACME Corp",
      "location": "Oakland, CA",
      "url": "https://example.com/job/123",
      "salary_range": "$140k-$180k",
      "tier": 1,
      "discovered_date": "2026-01-15",
      "match_score": 8,
      "maxime_score": null,
      "score_date": null,
      "status": "active",
      "applied_date": null,
      "notes": ""
    }
  ]
}
```

### Field Definitions

| Field | Type | Description |
|---|---|---|
| `schema_version` | string | Always `"1.1"` |
| `last_id` | integer | Current highest assigned ID (increment for each new offer) |
| `offers[].id` | string | Zero-padded 3-digit string (e.g. `"042"`) |
| `offers[].title` | string | Job title as scraped |
| `offers[].company` | string | Company name |
| `offers[].location` | string | Location string |
| `offers[].url` | string | Canonical URL for deduplication |
| `offers[].salary_range` | string | Salary range or `"Not disclosed"` |
| `offers[].tier` | integer | 1, 2, or 3 |
| `offers[].discovered_date` | string | ISO date when first found |
| `offers[].match_score` | integer | Andy's score 1-10 |
| `offers[].maxime_score` | integer or null | Maxime's score -1 to 5; null = unreviewed |
| `offers[].score_date` | string or null | ISO date when Maxime scored it |
| `offers[].status` | string | See valid values below |
| `offers[].applied_date` | string or null | ISO date of application submission |
| `offers[].notes` | string | Freeform notes, feedback, context |

### Valid Status Values

| Status | Set by | Meaning |
|---|---|---|
| `active` | Job Hunt discovery | Discovered, not yet reviewed by Maxime |
| `shortlisted` | Job Hunt reply processing | maxime_score >= 3 |
| `applied` | Lead Tracking Phase 2 | Application submitted |
| `passed` | Job Hunt reply or Lead Tracking | Maxime chose not to pursue (soft pass) |
| `discarded` | Job Hunt reply (score=-1) | Permanently removed from surfacing |
| `closed` | Lead Tracking | Position filled or removed |
| `withdrawn` | Lead Tracking | Maxime withdrew application |

### DECIDED_STATUSES (not surfaced in future hunts)

```python
DECIDED_STATUSES = {"applied", "discarded", "passed", "closed", "withdrawn"}
```

Offers in these statuses are never surfaced in future digest emails, even if re-discovered.

---

## Shared Artifact: metrics.json

**Written by:** All three missions
**Read by:** Lead Tracking Phase 7, career_promotion-optimizer skill

**Path:** `memory/metrics.json`

### Schema

```json
{
  "schema_version": "1.0",
  "job_hunt": {
    "runs": [
      {
        "date": "2026-01-20",
        "new_offers": 5,
        "total_unreviewed": 12,
        "email_sent": true,
        "phases_run": ["local", "regional", "relocation", "digest", "signals"]
      }
    ]
  },
  "lead_tracking": {
    "pipeline_snapshot": {
      "date": "2026-01-20",
      "shortlisted": 3,
      "ready_to_apply": 1,
      "applied": 2,
      "screening": 1,
      "interview_scheduled": 0,
      "offer": 0,
      "rejected": 4,
      "withdrawn": 0
    },
    "health_alerts": [
      {
        "date": "2026-01-20",
        "metric": "days_since_last_new_lead",
        "value": 23,
        "threshold": 21,
        "level": "yellow"
      }
    ]
  },
  "interview_coach": {
    "sessions": [
      {
        "date": "2026-01-20",
        "company": "ACME Corp",
        "role": "Senior Grid Engineer",
        "interview_type": "phone_screen",
        "outcome": "passed_to_next_round"
      }
    ]
  }
}
```

### Update Rules

- **Job Hunt:** Append to `job_hunt.runs` after each run (Phase 4 Step 11)
- **Lead Tracking:** Overwrite `lead_tracking.pipeline_snapshot` with latest state; append health alerts (Phase 7)
- **Interview Coach:** Append to `interview_coach.sessions` after each debrief (Phase 7)
- **Staleness:** If `job_hunt.runs` last entry is > 30 days old → career_promotion-optimizer should flag "metrics stale"

---

## Warning Log Format

**Path:** `memory/logs/handoff_warnings.log`

Append-only. One line per warning:

```
YYYY-MM-DD HH:MM STALE_HANDOFF: job_hunt_flagged.json entry #042 not ingested after 14 days
YYYY-MM-DD HH:MM STALE_HANDOFF: lead_to_interview.json entry lt_2026-01-10_001 no debrief after 7 days
YYYY-MM-DD HH:MM METRICS_STALE: metrics.json last updated 32 days ago
```

**Format:** `YYYY-MM-DD HH:MM <WARNING_CODE>: <detail>`

**Warning codes:**
- `STALE_HANDOFF` — handoff entry past expiry threshold
- `METRICS_STALE` — metrics.json not updated in > 30 days
- `INJECTION_DETECTED` — prompt injection attempt in external content (also log to audit.log)
- `REGISTRY_SCHEMA_MISMATCH` — unexpected field or missing required field in job_registry.json

---

## Audit Log

**Path:** `memory/logs/audit.log`

For security events only:

```
YYYY-MM-DD HH:MM INJECTION_DETECTED source=<url> pattern="ignore previous instructions"
YYYY-MM-DD HH:MM AUTH_CLI_BLOCKED command="gws auth login" prevented=true
```

---

## Staleness Rules Summary

| File | Staleness condition | Action |
|---|---|---|
| `job_hunt_flagged.json` entry | `ingested: false` AND `generated_date` > 14 days | Set `ingested: "stale"`, log warning |
| `lead_to_interview.json` entry | `interview_outcome: null` AND `interview_date` > 7 days ago | Set `interview_outcome: "no_debrief_recorded"`, log warning |
| `metrics.json` | Last job_hunt run > 30 days ago | career_promotion-optimizer logs "metrics stale" |
| `job_registry.json` | Offer `status: "active"` AND `discovered_date` > 60 days AND `maxime_score: null` | Consider marking `status: "closed"` — ask Maxime |
