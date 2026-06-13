# Handoff Pending Contract

## `job_hunt_flagged_pending.json`

**Location:** `workspace/memory/handoffs/job_hunt_flagged_pending.json`

**Purpose:** Bridge between weekly Job Hunt and Lead Tracking ingest. The job hunt writes candidate items here; Lead Tracking Phase 1 reads them.

**Schema (observed):**
```json
{
  "date": "YYYY-MM-DD",
  "offers": [
    {
      "registry_id": "NNN",
      "title": "Role title",
      "company": "Company name",
      "location": "Location string",
      "url": "https://...",
      "salary_range": "$range",
      "score": 8,               // match_score from hunt analysis, NOT maxime_score
      "tier": 1,                // 1-3 location/relocation tier
      "notes": "Free-text notes from hunt analysis"
    }
  ]
}
```

## Ingest Flow (Actual)

1. Job Hunt run writes pending items to `job_hunt_flagged_pending.json` with `score` (match_score).
2. Digest is sent to Maxime with these items.
3. Items sit pending until Maxime provides `maxime_score` via Telegram feedback or direct scoring.
4. Maxime assigns maxime_score (1-5) through scoring interactions.
5. Lead Tracking Phase 1 scans the pending file. Items with `maxime_score >= 1` (from prior feedback sessions) are ingested into `job_leads.json` with `status: "preparing"`.
6. Ingested items are *removed* from the pending file (not flagged with `ingested` — the file is consumed item-by-item).

## What the Mission Spec Says vs Reality

| Mission Spec (`mission_lead-tracking.md`) | Reality |
|---|---|
| Reads from `job_hunt_flagged.json` | File is `job_hunt_flagged_pending.json` (no non-pending variant exists) |
| Items have `maxime_score` & `ingested` fields | Items have `score` (match_score) — no maxime_score or ingested fields |
| Ingests directly if maxime_score >= 1 | Items need Maxime's scoring first; without it they stay pending |
| Marks ingested=true in the file | Items are removed from the pending file after ingestion |

## Staleness Handling

- Items pending >7d without Maxime scoring → flag in Lead Tracking report (pipeline bottleneck)
- Items pending >14d → escalate as cold handoff
- Items with `score >= 8` (high match_score) pending >7d → consider re-flagging in next digest as high-value items Maxime may have missed

## Edge Cases

- **Empty pending file** → skip Phase 1 (already handled: "No handoff file -> skip Phase 1")
- **Pending file has 0 items with maxime_score** → Phase 1 produces nothing; report as "N items pending your scoring" in Phase 2 output
- **Job hunt didn't run** → No pending file exists → Phase 1 is a no-op
