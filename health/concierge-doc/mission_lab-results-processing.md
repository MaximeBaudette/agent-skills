# Mission: lab-results-processing

**Trigger:** Maxime shares lab results (text, image, PDF, screenshot, or pasted values), or explicitly requests a lab snapshot update.  
**Cron:** None — invoked on demand.  
**Silent rule:** Not applicable — always confirm to Maxime after completion.

This is the authoritative execution spec. Follow every step exactly.

See `workspace/AGENTS.md` for KB update rules.

---

## Source of Truth

`labs.db` — SQLite database, table `labs` — is the **canonical, authoritative store** for all lab and biomarker history.

The KB page `health/snapshot/lab_results` (cooper-owned) is the **derived presentation** (the only "lab_results" view presented to agents/users). It is never canonical. Do not read the KB `lab_results` page to reconstruct history; always query `labs.db`.

---

## Database Schema

Table: `labs`

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK autoincrement | |
| `timestamp` | TEXT | ISO datetime of the measurement, e.g. `2026-04-03 07:49:59`. Use the real measurement date, not the insertion time. |
| `test_name` | TEXT | Canonical name, e.g. `HbA1c`, `HDL-C`, `eGFR` |
| `value` | REAL | Numeric only — strip units before storing. Always convert strings to float. |
| `unit` | TEXT | e.g. `%`, `mg/dL`, `ng/mL` |
| `ref_low` | REAL or NULL | Lower bound of healthy reference range (NULL if one-sided or unavailable) |
| `ref_high` | REAL or NULL | Upper bound of healthy reference range (NULL if one-sided or unavailable) |
| `notes` | TEXT | Brief context, e.g. `"↓ from 50 Feb25 | Kaiser baseline"` |

**Important:** `labs.db` is a binary SQLite file. Never use `read_file` on it. Always use `sqlite3` in `code_execution`.

---

## Step 1 — Insert New Values

Parse all new lab values from Maxime's input. Use the real measurement date as `timestamp` (from the lab report or report date). Out-of-order uploads are valid.

```python
import sqlite3
from pathlib import Path
from datetime import datetime

db = Path("labs.db")
conn = sqlite3.connect(db)

measurement_date = "2026-04-03 00:00:00"  # Use real date from lab report

new_labs = [
    # (test_name, value, unit, ref_low, ref_high, notes)
    ("HbA1c",         5.3,   "%",     4.0,  5.6,   "Mar 31 2026 Kaiser"),
    ("Triglycerides", 200.0, "mg/dL", 0.0,  150.0, "↑121 from Feb25"),
    # ... all parsed values
]

conn.executemany(
    "INSERT INTO labs (timestamp, test_name, value, unit, ref_low, ref_high, notes) "
    "VALUES (?, ?, ?, ?, ?, ?, ?)",
    [(measurement_date, *row) for row in new_labs]
)
conn.commit()
conn.close()
print(f"Inserted {len(new_labs)} lab(s)")
```

**Notes:**
- `value` must be REAL — always convert strings to float before inserting.
- For one-sided ranges (e.g. eGFR >90): set `ref_low=90, ref_high=None` or `ref_low=None, ref_high=X`.
- `ref_low` and `ref_high` represent the clinically healthy target range, not just the lab printout reference — apply clinical judgment.

---

## Step 2 — Query Latest Value Per Biomarker

Latest-by-timestamp semantics: the most recent **measurement date** wins, regardless of insertion order.

```python
import sqlite3
from pathlib import Path

db = Path("labs.db")
conn = sqlite3.connect(db)

rows = conn.execute("""
    SELECT test_name, value, unit, ref_low, ref_high, notes, timestamp
    FROM (
        SELECT *, ROW_NUMBER() OVER (
            PARTITION BY test_name ORDER BY timestamp DESC, id DESC
        ) AS rn
        FROM labs
    )
    WHERE rn = 1
    ORDER BY test_name
""").fetchall()
conn.close()
```

---

## Step 3 — Classify and Format

Emoji classification:

| Emoji | Condition |
|---|---|
| 🟢 | In reference range |
| 🔵 | Slightly below ref (80–100% of `ref_low`) |
| 🟣 | Much below ref (<80% of `ref_low`) |
| 🟠 | Slightly above ref (100–150% of `ref_high`) |
| 🔴 | Much above ref (>150% of `ref_high`) |
| ⚪ | No reference range available |

```python
def classify(value, ref_low, ref_high):
    if ref_low is None and ref_high is None:
        return "⚪"
    if ref_high is not None and value > ref_high:
        return "🔴" if value / ref_high > 1.5 else "🟠"
    if ref_low is not None and value < ref_low:
        return "🟣" if ref_low > 0 and value / ref_low < 0.8 else "🔵"
    return "🟢"

def ref_str(low, high):
    if low is None and high is None: return ""
    if low is None: return f"ref <{high}"
    if high is None: return f"ref >{low}"
    return f"ref [{low}–{high}]"
```

Line format per biomarker:
```
{test_name}: {emoji} {value} {unit} — {date} | {notes or "–"} | {ref_str}
```

---

## Step 4 — Update the owned KB page `health/snapshot/lab_results` (authoritative)

There is **no local `snapshot/lab_results.md`** in this profile. The KB page `health/snapshot/lab_results` (cooper-owned) is the source of truth and the only place the derived presentation lives.

After inserting into `labs.db`:
- (Optional but recommended) Use `kb_get_page("health/snapshot/lab_results")` to load the current version for context/diffing.
- Group the latest biomarkers by category (Metabolic/IR, Lipids, Liver, Inflammation, Renal, Hormones, CBC — add as needed). Alphabetize within categories.
- Build the full new markdown with this header style:
```
# Lab Results — Latest Key Metrics
<!-- Format: emoji Value unit — Date | delta/notes | ref [low–high] -->
<!-- Source of truth: labs.db (local). This KB page is the derived presentation. -->
<!-- Generated: YYYY-MM-DD -->
```
- Then one `**Category:**` block per group with the biomarker lines.
- Call the `knowledge-base` skill's `authoritative_push` helper (or direct `kb_authoritative_push`):
  - slug: "health/snapshot/lab_results"
  - content: the full new markdown
  - author: "cooper"
- This goes through the direct authoritative path (encyclopedist does light frontmatter + cross-links only; your generated body is preserved nearly verbatim).
- Confirm success.

**This KB page is the only "lab_results" presentation.** Do not create or write any local snapshot file.

---

## Step 5 — Set the event-driven refresh flag

After `labs.db` and the KB `health/snapshot/lab_results` page are updated, immediately set `memory/health_refresh_flags.json`:

```json
{
  "batch_refresh_pending": true,
  "set_at": "<preserve the existing value if already pending; otherwise now UTC>",
  "source": "lab-results-processing",
  "reason": "Updated labs: <short summary>",
  "last_cleared_at": "<leave unchanged>"
}
```

This flag is what wakes the next `health-monitor` cron run. If the flag is already pending, keep the earlier `set_at` so the next batch refresh still covers the full pending window.

---

## Step 6 — Confirm to Maxime

Reply with a concise summary:
- How many values were inserted
- Notable changes or new flags (🔴/🟠)
- Anything resolved or improved
- Any values missing reference ranges (⚪) that may need clinical context added

---

## Key Paths (relative to profile root)

| Path | Purpose |
|---|---|
| `labs.db` | **Source of truth** — canonical timestamped lab history (SQLite) — local to profile |
| `health/snapshot/lab_results` (Prime Radiant only) | The derived presentation view. Read with `kb_get_page`, update with `authoritative_push` (author="cooper"). No local file version exists in the profile. |
| `memory/health_refresh_flags.json` | Shared event-driven refresh flag; set after lab-state writes |
