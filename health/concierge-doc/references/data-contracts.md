# Cooper Data Contracts

See `workspace/AGENTS.md` for general ops, KB page ownership, retrieval (kb_get_page) and update (authoritative_push) rules for the health/snapshot/* pages. This is the canonical schemas/invariants reference.

Canonical schemas and invariants for all state files, snapshot files, and the lab database.

**Profile root:** `/home/mars/.hermes/profiles/health-coach/`

---

## 1. `labs.db`

**Owner:** `lab-results-processing` mission  
**Type:** SQLite database  
**Role:** Authoritative longitudinal store for all lab and biomarker history.

**Contract:**
- New values are inserted with their real measurement timestamps (not insertion timestamps)
- Out-of-order uploads are valid and handled correctly
- Downstream snapshot generation uses **latest-by-timestamp** semantics, not latest-inserted
- No mission treats `lab_results` KB page as the canonical history source — `labs.db` is
- Multiple timestamped entries per biomarker are valid and preserved

---

## 2. `health/snapshot/lab_results` (Prime Radiant, cooper-owned)

**Owner:** `lab-results-processing` mission (via `authoritative_push`)  
**Role:** Derived current-state presentation (the only "lab_results" view). Source of truth is the KB page.

**Contract:**
- Populated/updated from `labs.db` (local) using latest-by-timestamp semantics via the mission + `authoritative_push`
- Grouped by category (e.g., Lipids, Thyroid, CBC)
- Biomarkers alphabetized within each category
- Reflects the single latest timestamped value per biomarker
- Read via `kb_get_page("health/snapshot/lab_results")`
- Updated via `authoritative_push(slug="health/snapshot/lab_results", content=..., author="cooper")`
- **Not the canonical history record** — `labs.db` is. Do not reconstruct full history from this page.

---

## 3. `health/snapshot/active_symptoms` (Prime Radiant, cooper-owned)

**Owner:** `active-symptom-tracking` mission (via `authoritative_push`)  
**Role:** Active and resolved symptom tracking table. The only version.

**Contract:**
- Valid multiline markdown — real newlines, not escaped `\n` sequences
- Includes a header row and separator row
- One symptom per row
- Required columns (6, in this order): `Symptom`, `Onset Date`, `Last Updated`, `Status`, `Next Follow-Up`, `Notes`
- `Status` is limited to exactly:
  - `active`
  - `resolved`
- Severity language (e.g., "mild", "moderate") belongs in `Notes`, not in `Status`
- `Last Updated` is `YYYY-MM-DD` — date of most recent update to the row
- `Next Follow-Up` is either:
  - ISO UTC datetime: `YYYY-MM-DD HH:MM UTC`
  - Empty string when resolved
- Legacy values such as `Active (mild)` or `monitoring` are not valid; normalize on contact

**Example row:**
```
| Seasonal allergy | 2026-03-15 | 2026-04-20 | active | 2026-04-20 09:00 UTC | Mild; Oak/birch pollen season |
```

---

## 4. `memory/pollen_log.md`  (note: actually under workspace/archive/pollen_log.md)

**Owner:** `daily-pollen-allergy-check` mission  
**Role:** Single canonical pollen history log.

**Contract:**
- The `daily-pollen-allergy-check` mission writes **only** to `archive/pollen_log.md` for pollen history
- No other path is valid for persistent, user-authored pollen history
- One entry per daily cron run; format determined by the mission file
- Vendored package artifacts such as `.../site-packages/.../pollen.v1.json` are explicitly **not** this file and are ignored
- If stray user-authored pollen logs are found outside this path, append their real entries here and remove the stray copies

---

## 5. `memory/health_refresh_flags.json`

**Owner:** Shared event-driven refresh pipeline (`health-monitor`, `active-symptom-tracking`, `lab-results-processing`, and direct health-state mutations documented in `workspace/AGENTS.md`)  
**Role:** Small persistent intent file telling the `health-monitor` gate whether a new batch refresh should be submitted.

**Contract:**
- `batch_refresh_pending` is `true` when a future `health-monitor` run should submit a fresh batch
- `set_at` is the earliest pending change timestamp for the current refresh window
- `source` is a short producer label such as `lab-results-processing` or `active-symptom-tracking`
- `reason` is a short human-readable summary of what changed
- `last_submitted_set_at` preserves the most recent submitted refresh window so failed downstream batch processing can be re-armed without losing context
- `last_cleared_at` records when a successful `submit_task.py` submission cleared the pending flag
- If the file is missing, `cron_gate_health_monitor.py` treats it as the default empty state

**Expected schema:**
```json
{
  "batch_refresh_pending": false,
  "set_at": null,
  "source": "",
  "reason": "",
  "last_submitted_set_at": null,
  "last_cleared_at": null
}
```

---

## 6. `memory/batch_state.json`

**Owner:** `health-monitor` mission (via `scan_memory.py`)  
**Role:** Session scan watermark. Tracks which daily session logs have been scanned.

**Contract:**
- Tracks the last scanned session date/position so `scan_memory.py` does not re-scan already-processed content
- Written by `scan_memory.py` after a successful scan
- Read by `health-monitor` at the start of each run to determine which sessions are new
- **Not** the batch lifecycle state — do not conflate with `state.json`

**Distinct from `state.json`:**

| File | Tracks |
|---|---|
| `memory/batch_state.json` | Which daily memory sessions have been scanned (scan watermark) |
| `state.json` | Whether a batch job is in flight and what its status is |

---

## 7. `state.json`

**Owner:** `health-monitor` mission (writes on submission) + gated batch-poll script path (`scripts/cron_gate_batch_poll.py` reads, `scripts/batch_poll.py` legacy)  
**Role:** Batch lifecycle state. Tracks the current xAI batch job.

**Contract:**
- `batches.combined` fields written by `submit_task.py` on successful batch submission
- `heartbeat.last_processed_at` is a retained fallback watermark from the earlier scan-based flow
- Read by `scripts/cron_gate_batch_poll.py` at the start of each cron poll run
- Read again by legacy paths only after the gate confirms an inflight combined batch
- Reset (cleared or set to idle) by `cron_gate_batch_poll.py` after a batch completes or fails
- The gate exits early when `batches.combined.status` is not `submitted`
- `xai_batch_id` is a top-level persistent batch container ID; the gated batch-poll flow does not clear it during reset
- **Not** the session scan watermark and **not** the event-driven refresh flag — do not conflate with `memory/batch_state.json` or `memory/health_refresh_flags.json`

**Failure-handling note:**
- When `cron_gate_batch_poll.py` hits an error after submission (API failure, parse failure, missing required sections), it resets `batches.combined` back to `idle` and re-arms `memory/health_refresh_flags.json` with `source = "batch-poll"` so the next `health-monitor` run can retry.

**Expected schema (nested):**
```json
{
  "heartbeat": {
    "last_processed_at": "<ISO UTC datetime or null>"
  },
  "batches": {
    "combined": {
      "request_id": "<string or null>",
      "submitted_at": "<ISO UTC datetime or null>",
      "status": "idle | submitted | processing | complete | failed"
    }
  },
  "xai_batch_id": "<string or null>"
}
```

> **Note:** `heartbeat.last_processed_at` is retained as a fallback watermark. The active event-driven `health-monitor` flow is keyed off `health_refresh_flags.json`, not this field.

---

## 8. Batch-Owned Snapshot Pages (Prime Radiant only)

These are **no longer local files**. They are cooper-owned pages in Prime Radiant under `health/snapshot/`.

They are updated exclusively by the `batch-poll` gate (after xAI batch result) via direct `authoritative_push`. No manual workflow or other mission writes to the local FS for them.

### `health/snapshot/health_summary`

**Contract:**
- Current executive health summary (flags, meds, supplements, lab highlights)
- The gate calls `authoritative_push` with the xAI-generated content.
- History via KB git. Other missions read via `kb_get_page`.

### `health/snapshot/treatment_plan`

**Contract:**
- Current evidence-graded treatment and deprescription plan
- Updated directly by the gate.

### `health/snapshot/differential_diagnostic`

**Contract:**
- Ranked differential or latent concerns
- Updated directly by the gate.

**Shared rules:**
- Owned by the batch flow.
- No local `archive/snapshots/` copies in the profile for new versions (historical only; use KB history).
- Other missions may read via `kb_get_page` for context.
- The interactive `batch-poll` mission can also trigger or review.
