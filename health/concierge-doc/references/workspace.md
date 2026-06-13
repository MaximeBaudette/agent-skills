# Cooper Workspace Map

Reference document for all file locations in the `health-coach` profile workspace.

See `workspace/AGENTS.md` (the active ops doc when CWD=workspace/) for general rules, owned KB pages, hard blocks, My Team, email, research delegation, and Prime Radiant workflows. This map is supporting detail.

**Profile root:** `/home/mars/.hermes/profiles/health-coach/`

---

## Health Snapshots (Prime Radiant / KB only - no local copies)

**Cooper has zero local copies of the health snapshot files.**

The files that used to live under `snapshot/` (active_symptoms.md, lab_results.md, health_summary.md, treatment_plan.md, differential_diagnostic.md) are now **exclusively** in Prime Radiant as cooper-owned pages:

- `health/snapshot/active_symptoms`
- `health/snapshot/lab_results`
- `health/snapshot/health_summary`
- `health/snapshot/treatment_plan`
- `health/snapshot/differential_diagnostic`

All access must go through Prime Radiant (knowledge-base skill):

- Read current state: `kb_get_page("health/snapshot/xxx")`
- Update: construct the new full markdown for the page, then `authoritative_push(slug="health/snapshot/xxx", content=the_markdown, author="cooper")`

This is the new paradigm: KB is the single source of truth. The concierge-doc missions, gates, and supporting scripts have been updated accordingly.

For Maxime's personal quick filesystem access (without navigating the full KB tree), there is a convenience symlink at:
`/home/mars/all_docs_quick-access/health-snapshot` → the KB `health/snapshot` dir.

**Note on labs.db:** The SQLite `labs.db` remains the local canonical history for raw lab/biomarker data. `lab_results` in the KB is the derived presentation view generated from it (or updated via lab-results-processing mission).

The old local `workspace/snapshot/` directory and any archives tied exclusively to it have been retired for the health snapshot files.

---

## `archive/snapshots/`

Versioned archives of the three batch-owned snapshot files (historical only, from before the 2026-04 KB-only transition). No new writes to this dir for the snapshots.

| Contents | Description |
|---|---|
| `YYYY_MM_DD_HHMM_health_summary.md` | Timestamped prior versions of health_summary (legacy) |
| `YYYY_MM_DD_HHMM_treatment_plan.md` | Timestamped prior versions of treatment_plan (legacy) |
| `YYYY_MM_DD_HHMM_differential_diagnostic.md` | Timestamped prior versions of differential_diagnostic (legacy) |

**Invariant:** No manual workflow writes these files. They are a historical record produced by the gated batch-poll completion path only (pre-transition). Current versions and history via KB git.

---

## `memory/`

Persistent memory files: daily session logs, state files, and the pollen history log.

| File/Dir | Content |
|---|---|
| `archive/pollen_log.md` | Canonical pollen history log; one entry per daily run |
| `health_refresh_flags.json` | Event-driven batch-refresh flag: set by health-state mutations, cleared by successful `submit_task.py` submission, and re-armed by `cron_gate_batch_poll.py` if downstream batch processing fails |
| `batch_state.json` | Retained session scan watermark for legacy/manual `scan_memory.py` use |
| `YYYY-MM-DD.md` files | Daily health notes: legacy `scan_memory.py` output plus direct-session notes that should feed the next batch refresh |

---

## Workspace Root

| File | Content |
|---|---|
| `labs.db` | Canonical, timestamped SQLite store for all lab and biomarker history |
| `AGENTS.md` | See `workspace/AGENTS.md` for the active operational rules (hard blocks, KB workflows, file access, My Team, etc.). Mission execution specs delegated to `skills/concierge-doc/`. |
| `state.json` | Batch lifecycle state (xAI batch ID, status, timestamps) |

---


## `skills/concierge-doc/`

The health operations hub skill and all mission/reference docs.

| File | Role |
|---|---|
| `SKILL.md` | Hub: mission registry, routing, cron table, workspace summary, file-ownership table, data-contract pointers, and tool/security rules |
| `mission_health-monitor.md` | Authoritative execution spec for health-monitor |
| `mission_batch-poll.md` | Authoritative manual/query spec plus agent follow-up after `scripts/cron_gate_batch_poll.py` wakes the agent |
| `mission_lab-results-processing.md` | Authoritative execution spec for lab-results-processing |
| `mission_active-symptom-tracking.md` | Authoritative execution spec for active-symptom-tracking |
| `mission_daily-pollen-allergy-check.md` | Authoritative execution spec for daily-pollen-allergy-check |
| `references/workspace.md` | This file |
| `references/data-contracts.md` | Canonical schemas and invariants for all state and snapshot files |
| `references/file-path-conventions.md` | Path resolution rules (CWD, absolute/relative, KB notes) |

---

## Legacy Flat Docs — Retired 2026-04-14

These four flat skill docs were the prior execution surface. They were retired and removed from the live skill surface on **2026-04-14** when the `concierge-doc` hub was confirmed working and crons were rerouted. **Do not treat these as authoritative specs or active files.**

| File | Superseded by |
|---|---|
| `skills/active-symptom-tracking.md` | `mission_active-symptom-tracking.md` |
| `skills/batch-poll.md` | `mission_batch-poll.md` |
| `skills/health-monitor.md` | `mission_health-monitor.md` |
| `skills/lab-results-processing.md` | `mission_lab-results-processing.md` |
