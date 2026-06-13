# Mission: health-monitor

**Cron:** `4a9cb328368c` | `0 6-22 * * *` (6 AM - 10 PM PT) | delivery: local  
**Authoritative cron entrypoint:** `scripts/cron_gate_health_monitor.py`  
**Silent rule:** Respond with `[SILENT]` if no batch was submitted and no symptom pings were sent.

This mission is the authoritative agent-side follow-up **after** the gate decides the LLM should wake. The gate owns the idle skip path.

---

## Gate contract

Cron job `4a9cb328368c` runs `scripts/cron_gate_health_monitor.py` first.

- If the gate returns `{"wakeAgent": false, ...}` the Hermes scheduler skips the agent entirely.
- If the gate returns `{"wakeAgent": true, "kind": "error", ...}` this mission must surface the error and stop.
- If the gate returns `{"wakeAgent": true, "kind": "health_monitor", ...}` this mission must use the injected JSON as the source of truth for which branches to run.

Expected work payload:

```json
{
  "wakeAgent": true,
  "kind": "health_monitor",
  "batch_refresh_pending": true,
  "source": "lab-results-processing",
  "reason": "Updated ApoB and triglycerides",
  "due_symptoms": []
}
```

`batch_refresh_pending` means "submit a batch now." If it is `false`, do not call `submit_task.py` on this run.

---

## Step 1 - Read the injected gate payload

Start from the injected JSON.

1. If `wakeAgent == false` and `kind` is `idle` or `processing`:
   - Respond with `[SILENT]`
   - Stop immediately
2. If `kind == "error"`:
   - Alert Maxime with the exact error message
   - Stop immediately
3. If `kind != "health_monitor"`:
   - Alert Maxime that the gate payload is invalid
   - Stop immediately
4. Otherwise:
   - Read `batch_refresh_pending`
   - Read `due_symptoms`
   - Treat those fields as authoritative for this run

Do **not** run `scan_memory.py` here. This mission no longer discovers work by rescanning sessions.

---

## Step 2 - Submit a batch only when requested by the gate

Only if `batch_refresh_pending == true`, execute `submit_task.py` via `code_execution`:

```python
import os
import pathlib
import subprocess

hermes_home = str(pathlib.Path(os.environ.get(
    "HERMES_HOME", str(pathlib.Path.home() / ".hermes/profiles/health-coach"))))
result = subprocess.run(
    ["python3", "scripts/submit_task.py"],
    cwd=hermes_home,
    env={**os.environ, "HERMES_HOME": hermes_home},
    capture_output=True,
    text=True,
)
print(result.stdout)
if result.stderr:
    print("STDERR:", result.stderr)
```

Interpret output:

| Output | Action |
|---|---|
| `combined batch submitted` | Success. `submit_task.py` already cleared `memory/health_refresh_flags.json`. |
| `batch already in flight` | No submission on this run. Leave the refresh flag untouched. |
| `Stale batch detected` followed by `combined batch submitted` | Success after reset. |
| Non-zero exit or `ERROR` | Alert Maxime. Leave the refresh flag untouched. |

If `batch_refresh_pending == false`, skip this step entirely.

---

## Step 3 - Send due symptom follow-ups

If `due_symptoms` is non-empty, send one Telegram message per row:

```
Symptom check-in: [Symptom]
Onset: [Onset Date] | Last updated: [Last Updated]
Notes: [Notes or "none"]
How is it going? (better / same / worse / resolved)
```

Then immediately update that row in `health/snapshot/active_symptoms (Prime Radiant, via kb_get_page + authoritative for limited updates)`:

- Set `Next Follow-Up` to now + 24h in `YYYY-MM-DD HH:MM UTC` format to prevent duplicate pings while awaiting response
- Set `Last Updated` to today (`YYYY-MM-DD`)

If `due_symptoms` is empty, skip this step.

---

## Step 4 - Silent exit rule

If both of the following are true:

- No batch was submitted in Step 2, and
- No symptom follow-up pings were sent in Step 3

Respond with `[SILENT]`.

---

## Notes

- `scripts/scan_memory.py` and `memory/batch_state.json` are retained as legacy/manual fallback surfaces. They are no longer part of the hourly cron path.
- Generic direct Cooper interactions that introduce clinically significant new health state must persist a concise note to today's `memory/YYYY-MM-DD.md` and set `memory/health_refresh_flags.json`. That persistence happens outside this cron mission.

---

## Key paths (relative to profile root)

| Path | Purpose |
|---|---|
| `scripts/cron_gate_health_monitor.py` | Authoritative cron gate for `4a9cb328368c` |
| `scripts/submit_task.py` | Batch submission entrypoint |
| `memory/health_refresh_flags.json` | Event-driven refresh flag consumed by the gate and cleared on successful submission |
| `state.json` | Batch lifecycle state |
| `health/snapshot/active_symptoms (Prime Radiant, via kb_get_page + authoritative for limited updates)` | Due symptom read surface; health-monitor may update `Next Follow-Up` and `Last Updated` on due rows |
| `memory/YYYY-MM-DD.md` | Optional direct-session health notes consumed by `submit_task.py` when a refresh is pending |
