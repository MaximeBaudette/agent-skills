# Registry Maintenance Techniques

Accumulated learnings from daily Job Registry Maintenance runs.

---

## Salary Enrichment: Glassdoor Search Snippets

**Problem:** Glassdoor blocks `web_extract` (returns empty/failed fetch), making it impossible to scrape the salary range from the page directly.

**Solution:** The employer-provided salary range often appears in the `web_search` result snippet. For example, searching `"{o.title}" {o.company} glassdoor salary` may return:

> *"The minimum salary is $149K and the max salary is $308K. $149K – $308K/yr (Employer provided). $229K. /yr Median."*

This is employer-provided data — the most credible source. Use the range from the snippet directly:

1. Run `web_search` with the Glassdoor salary query (don't try `web_extract` on the Glassdoor URL)
2. Extract the range from the snippet text
3. Note the source in `o.notes`: `Salary enriched YYYY-MM-DD: $X-$Y (Glassdoor employer-provided range, snippet)`
4. Set `o.salary_range = "$X-$Y"`

**When to skip:** If the snippet shows estimated/third-party ranges (e.g., "Glassdoor est. $X-$Y") rather than "Employer provided", treat as less reliable and cross-reference with another source.

---

## Schema Discipline: No Ad-Hoc Fields

**Rule:** The `job_registry.json` schema v1.1 has a fixed set of fields per offer. Do **not** add new fields like `last_verified_date` unless you're also updating the schema version and all downstream consumers.

**Verification tracking** uses the existing `notes` field with the conventional format:

```
Verified active YYYY-MM-DD: listing accessible.
```

This is how every existing offer in the registry tracks verification history. Stick to this convention.

**Rationale:** Adding `last_verified_date` as a new field creates an inconsistency:
- Not all offers will have it (null-safety issues in downstream code)
- Downstream scripts (`score_leads.py`, `generate_digest.py`) that iterate over offer dicts don't expect this field
- Schema drift without version bump breaks the data contract

If you need programmatic verification tracking, update schema_v2 with a `verified_history: [{"date": "YYYY-MM-DD", "status": "active"}]` field, bump `schema_version`, and migrate all offers in one pass.

---

## Handoff Warnings Log: Init

**Problem:** The mission spec references `memory/handoffs/handoff_warnings.log` but the file may not exist yet (no init step documented).

**Solution:** Before appending, check if the file exists and create it with an empty array if absent. In Python:

```python
import os
path = "/home/mars/.hermes/profiles/career-manager/workspace/memory/handoffs/handoff_warnings.log"
os.makedirs(os.path.dirname(path), exist_ok=True)
if not os.path.exists(path):
    with open(path, "w") as f:
        f.write("")
```

The same init pattern applies to any log path in `memory/logs/`.

---

## Change Log: Writing Convention

When writing the daily changes log to `memory/logs/registry_maintenance/YYYY-MM-DD_changes.json`:

```json
{
  "date": "YYYY-MM-DD",
  "total_checked": N,
  "stale_marked": M,
  "salary_enriched": K,
  "notes_added": L,
  "changes": [
    {"id": "042", "type": "stale", "detail": "page returned 404"},
    {"id": "068", "type": "salary_enriched", "detail": "Not disclosed → $149K-$308K"}
  ]
}
```

**Watch for f-string dollar-sign bugs:** When building the change detail in Python f-strings, use `${...}` interpolation carefully. A write like `f"${new_range}"` won't substitute — use `f"${new_range}"` (but that's not valid Python either — the actual syntax is `f"${variable}"` where `$` is literally a dollar sign). To be safe: `f"${found_range}"` in a Python f-string will output `${found_range}` literally since `$` is not a Python interpolation trigger. However, if you're building JSON with `json.dumps` later, just construct the string with concatenation or `format()`.

---

## LinkedIn Extraction Signals for Stale Detection

When `web_extract` succeeds on a LinkedIn job page, check for these reliable stale markers in the extracted text:

| Signal in extracted content | Interpretation | Action |
|---|---|---|
| `"No longer accepting applications"` | Role closed | Mark `closed` immediately |
| `"This job is no longer accepting applications"` | Role closed | Mark `closed` immediately |
| `"Be among the first 25 applicants"` | Still accepting | Active — fresh posting |
| `"X applicants"` (with count) | Still accepting | Active — but competitive |
| `"Posted X months ago"` + no applicant badge | May be auto-expired | Cross-check with `web_search` |

**Important:** If LinkedIn shows a sign-in modal but no explicit "No longer accepting" text, the listing is still active — modals only appear on live postings. If the page title contains "(Expired)" or "(Closed)", the role is inactive.

---

## Browser Verification: This Session's Notes

- **#050 Stanley Consultants:** `web_extract` on LinkedIn returned explicit "🚫 No longer accepting applications" badge — definitive closed signal. Use LinkedIn-extracted application-status badges as first-class stale markers.
- **#055/#056 Tesla:** Bot/geo-blocked on both `browser_navigate` and `web_extract`. Both confirmed active via Indeed/LinkedIn aggregator search. Use aggregator fallback as canonical verification if employer page is blocked.
- **#064 Leidos (MyWorkdayJobs):** Cloudflare/verification gate consistently blocked. LinkedIn aggregator search confirmed active. Mark `active` with note `Cloudflare blocked, verified via aggregator`.
- **#067 Nextracker (ZipRecruiter):** Cloudflare blocked. Logged to `handoff_warnings.log` as needs_manual_check. Kept `active` since external signals suggest listing is live.
- **#052 HDR (LinkedIn):** Confirmed active. Posting shows "Be among the first 25 applicants" — indicator of fresh/recent posting.
- **#075 Vestas:** `web_extract` on `careers.vestas.com` returns full structured JD (responsibilities, qualifications, compensation) — one of the most complete extractions. Excellent source for JD summaries.
- **#059 Revamp Engineering (Climatebase):** Listing persisted 2+ months on Climatebase after original posting. Climatebase listings are long-lived — if the page loads, the role is still active even if old.
