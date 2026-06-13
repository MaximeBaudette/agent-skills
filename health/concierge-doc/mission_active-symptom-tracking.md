# Mission: active-symptom-tracking

**Trigger:** Maxime mentions a new physical complaint, responds to a symptom follow-up, or reports a change or resolution of a known symptom.  
**Cron:** None — invoked on demand only. (`health-monitor` does **not** invoke this mission as a subroutine; it performs a limited direct update to the owned KB page `health/snapshot/active_symptoms` on due follow-up rows — updating only `Next Follow-Up` and `Last Updated` — as an explicitly allowed exception documented in File Ownership below. The gate already reads the page via `kb_get_page` to build the due list.)  
**Silent rule:** Not applicable — always confirm action taken to Maxime.

This is the authoritative execution spec. Follow every step exactly.

See `workspace/AGENTS.md` and `references/data-contracts.md` for the table contract and KB update rules.

---

## File Ownership

`health/snapshot/active_symptoms` (Prime Radiant, cooper-owned) is **owned exclusively by this mission**. Only this mission (and the limited health-monitor exception) writes to it.

No other mission writes to this page. It is not batch-owned.

`memory/health_refresh_flags.json` is a shared pipeline file. This mission must set it after any symptom-state mutation so the next `health-monitor` run knows a batch refresh is pending.

---

## File Format (for the KB page content)

Valid multiline markdown — real newlines, not escaped `\n` sequences.

```markdown
# Active Symptoms — Maxime Baudette

<!-- Cooper reads this file on every heartbeat to check for due follow-ups. -->
<!-- If this table has no active rows, the symptom check-in is skipped entirely. -->
<!-- Next Follow-Up: ISO datetime (YYYY-MM-DD HH:MM UTC). Use "" (empty) when resolved. -->

| Symptom | Onset Date | Last Updated | Status | Next Follow-Up | Notes |
|---|---|---|---|---|---|
| Left knee pain | 2026-04-01 | 2026-04-10 | active | 2026-04-17 09:00 UTC | Mild; worsened after run |
| Seasonal allergy | 2026-03-15 | 2026-04-20 | resolved | | Resolved with topicals |
```

---

## Schema

| Column | Format | Rules |
|---|---|---|
| `Symptom` | Plain text | Short name, e.g. `Left knee pain`, `Fatigue` |
| `Onset Date` | `YYYY-MM-DD` | Date Maxime first mentioned it |
| `Last Updated` | `YYYY-MM-DD` | Date of most recent update |
| `Status` | `active` or `resolved` | **Only these two values.** See Status Normalization below. |
| `Next Follow-Up` | `YYYY-MM-DD HH:MM UTC` or `""` | ISO UTC datetime. Empty string when resolved. |
| `Notes` | Plain text | Context, severity, new info, differentials |

---

## Status Normalization

`Status` accepts **only** `active` or `resolved`. No other values are valid.

**On any contact with the page:** normalize legacy or drifted values immediately:

| Legacy value | Normalize to |
|---|---|
| `Active (mild)` | `active` (move "mild" to `Notes`) |
| `Active (moderate)` | `active` (move "moderate" to `Notes`) |
| `monitoring` | `active` |
| `Resolved` (capital R) | `resolved` |
| Any other non-standard value | use clinical judgment; default to `active` if uncertain |

**Severity language belongs in `Notes`, not in `Status`.** Examples: "Mild; Oak/birch season", "Moderate; worsening after exercise".

---

## Adding a New Symptom

**Rule:** Log only what Maxime explicitly states — never infer or fabricate symptoms.

1. Read current via `kb_get_page("health/snapshot/active_symptoms")` (for context / to copy existing table).
2. Append a new row with `Status: active`
3. Set `Next Follow-Up` based on clinical severity:

| Severity | Examples | Follow-Up interval |
|---|---|---|
| Urgent | Active bleeding, chest pain, severe pain, fever >39°C | 1–4 hours |
| Moderate | Fever, acute injury, significant GI symptoms, infection signs | 12–24 hours |
| Mild / Chronic | Rash, low-grade fatigue, minor aches | 48–72 hours |
| Monitoring | Improving, stable chronic condition | 3–7 days |

4. Build the full updated markdown (header comments + table with real newlines).
5. Call `authoritative_push` (via knowledge-base skill or direct):
   - slug = "health/snapshot/active_symptoms"
   - content = the full updated markdown
   - author = "cooper"

6. Immediately set `memory/health_refresh_flags.json`:

```json
{
  "batch_refresh_pending": true,
  "set_at": "<preserve the existing value if already pending; otherwise now UTC>",
  "source": "active-symptom-tracking",
  "reason": "Added symptom: <short symptom summary>",
  "last_cleared_at": "<leave unchanged>"
}
```

---

## Updating an Existing Symptom

When Maxime responds to a follow-up, or mentions a known symptom during a session:

1. (Optional for context) `kb_get_page("health/snapshot/active_symptoms")`
2. Set `Last Updated` to today's date (YYYY-MM-DD)
3. Append new information to `Notes`
4. Update `Status` and `Next Follow-Up` based on reported trajectory:

| Trajectory | Action |
|---|---|
| **Resolved** | Set `Status = resolved`, set `Next Follow-Up = ""` (empty string) |
| **Ongoing / same** | Set new `Next Follow-Up` based on current severity |
| **Improving** | Lengthen follow-up interval (3–7 days) |
| **Worsening** | Shorten follow-up interval to 1–4h. Consider advising Maxime to seek medical attention. |

5. Build the full updated markdown table (preserve header comments about Cooper reading for follow-ups).
6. **Update the owned KB page (authoritative)**: call `authoritative_push` (knowledge-base skill):
   - slug = "health/snapshot/active_symptoms"
   - content = the full updated table/markdown
   - author = "cooper"
   This is the durable shared version for all agents.

7. Immediately set `memory/health_refresh_flags.json`:

```json
{
  "batch_refresh_pending": true,
  "set_at": "<preserve the existing value if already pending; otherwise now UTC>",
  "source": "active-symptom-tracking",
  "reason": "<short symptom change summary>",
  "last_cleared_at": "<leave unchanged>"
}
```

---

## Follow-Up Rules

- `Next Follow-Up` must always be a valid ISO UTC datetime (`YYYY-MM-DD HH:MM UTC`), or `""` (empty string) when resolved.
- Never write `"resolved"`, `"N/A"`, `"–"`, or any other non-datetime, non-empty value to `Next Follow-Up`.
- Do not remove resolved rows — set `Status = resolved` and clear `Next Follow-Up` to `""`.
- Do not add differential analysis to this page — that belongs to `health/snapshot/differential_diagnostic` (batch-owned).

---

## Key Paths (relative to profile root)

| Path | Purpose |
|---|---|
| `health/snapshot/active_symptoms` (Prime Radiant only) | Active and resolved symptom register — exclusively owned by this mission. Read exclusively with `kb_get_page`. Update exclusively with `authoritative_push` (author="cooper"). No local copy exists in the profile. |
| `memory/health_refresh_flags.json` | Shared event-driven refresh flag; set after symptom-state writes |
