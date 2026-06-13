---
name: job_data_enrichment
description: "Extract structured data from job posting web pages using fallback strategies when primary methods fail. Use for enriching salary ranges, checking job status, and extracting notes from job URLs."
version: 1.0.0
author: Andy (career-manager)
license: MIT
---

# Job Data Enrichment Skill

Extracts structured data (salary ranges, job status, notes) from job posting web pages using robust fallback strategies.

## When to Use
- Enriching missing salary_range fields in job_registry.json
- Checking if a job posting is still active (not stale)
- Extracting summary notes from job descriptions
- Any job data extraction task from web pages

## Approach
Follow this sequence for each job URL:

### Step 1: Attempt Primary Navigation
**In execute_code context**: Use the tool interface
```python
from hermes_tools import browser_navigate
result = browser_navigate({'url': url})
# Check result.get('success') for True/False
```

**In non-execute_code context** (like direct tool use):
```\nbrowser_navigate(url)\\n```
- If successful (returns {"success": true}), proceed to Step 2
- If fails with network/error, proceed to Step 1b

### Step 1b: Handle Navigation Failure
If browser_navigate fails (network errors, timeouts, etc.):
1. Wait 2 seconds
2. Retry browser_navigate (max 2 retries total)
3. If still failing, try web_extract as fallback
4. If web_extract fails/blocked or returns insufficient content, wait and retry browser_navigate once more
5. If all attempts fail, skip enrichment for this URL

Note: In execute_code contexts where browser tools are not available, start directly with web_extract as the primary method.

### Step 2: Extract Page Content
Once you have successfully retrieved content (via navigation or web_extract):
**Primary method**: Use browser_console to get visible text
```\\nbrowser_console(expression="document.body.innerText")\\n```
This reliably gets visible text content without being blocked by network restrictions.

**In execute_code context**: 
```python
from hermes_tools import browser_console
result = browser_console({'expression': 'document.body.innerText'})
# Access result.get('output') for the text content
```

**Fallback method**: If browser_console is not available or fails, use the content from browser_snapshot or web_extract.

Note: Some sites (like Tesla careers) may return "Access Denied" to automated browsers. In such cases:
1. Try accessing the mobile version of the site if available
2. Try web_extract as an alternative
3. As a last resort, use web_search to find salary information from third-party sites (levels.fyi, glassdoor, etc.)

### Step 3: Parse Extracted Text
From the console output, extract:

**Salary Range:**
- Look for patterns: 
  - `\$\d{1,3}(?:,\d{3})*(?:\s*-\s*\$\d{1,3}(?:,\d{3})*)?` (e.g., $112,000 - $168,000)
  - `\$\d+k\s*-\s*\$\d+k` (e.g., $113k-$188k)
  - "pay range is between \$X and \$Y"
  - "expected compensation range is \$A - \$B"
- Convert to standard format: "$LOWk-$HIGHk" (round to nearest k)
- If multiple ranges found, take the most credible (typically the first explicit range)

**Stale Status Indicators:**
Check for these phrases (case insensitive):
- "position no longer available"
- "job is closed"
- "position has been filled"
- "not accepting applications"
- "application deadline passed" (if date is in past)
- "this role is no longer available"
If found, mark job as stale.

**Notes Extraction:**
If notes field is empty:
- Extract 1-2 sentence summary focusing on responsibilities matching user's skills
- Append the summary directly to the notes field (no timestamp prefix — the digest script strips enrichment metadata lines)
- Look for sections like "Responsibilities", "What You'll Do", "Key Duties"

### Step 4: Update Job Registry
For each successfully enriched field:
- Update the specific field in job_registry.json (salary_range, status, etc.)
- For notes enrichment: append the extracted summary directly (no timestamped metadata prefix)
- Track changes for logging and metrics

## Error Handling
| Error Condition | Action |
|---|---|
| All navigation attempts fail | Skip enrichment, log warning |
| web_extract blocked (private/internal network) | Proceed to browser_console retry |
| No salary pattern found | Leave salary_range unchanged |
| No stale indicators found | Job remains active |
| Parsing fails | Skip field enrichment, continue |

## Site Reliability Notes (from operational experience)

| Site / Pattern | Reliability | Notes |
|---|---|---|
| Direct company careers (Tesla, GE Vernova, Schneider) | High | Explicit salary ranges; stable URLs |
| iCIMS portals | Medium-High | Content loads in iframe; use `browser_console(expression="document.body.innerText")` |
| LinkedIn direct | Medium | Expired jobs redirect to `trk=expired_jd_redirect` — detect in URL |
| Indeed / ZipRecruiter | Low | Systematically blocked by Cloudflare verification; skip or mark stale |
| JobLeads / aggregator links | Low | Often redirect to search pages, not direct listings; verify before enriching |
| Fox8 / job board syndicators | Medium | May show "job expired" explicitly — reliable for stale detection |

**Location Discrepancies:** Always compare the extracted location against the recorded `location` field. LinkedIn and board aggregators frequently mismatch city vs. remote vs. HQ location. Update the registry when discrepancies are found.

## Batch Processing & Orchestration
When validating >10 URLs in a single maintenance run, use parallel subagents via `delegate_task`:
- Group URLs by platform (LinkedIn, Tesla, iCIMS, Workday, etc.) so each subagent can apply platform-specific workarounds
- Provide each subagent with the offer ID, URL, current salary, and current notes
- Return structured JSON: `{id, status, reason, salary_enrichment_needed, notes_enrichment_needed}`
- Central agent merges results, updates registry, and writes the change log

**Platform workarounds to encode in subagent prompts:**
- LinkedIn → dismiss sign-in modal first (`browser_click(ref="@e1")`)
- Tesla careers → append `?source=careers` to URL if Access Denied
- iCIMS portals → use `web_extract` directly (content lives in iframe)
- Cloudflare gates (ZipRecruiter, some aggregators) → mark `needs_manual_check`, do not auto-close

## Registry Hygiene Patterns

### Notes Deduplication
Enrichment metadata lines (with timestamp prefixes) should no longer be written to notes (see Step 4 above). However, legacy entries may still contain them. When re-processing the same offer across multiple maintenance runs, remove any timestamped enrichment lines completely:

```python
lines = notes.split("\n")
cleaned = []
for line in lines:
    if line.startswith(("Closed:", "Salary enriched", "JD summary", "Verified active", "Notes enriched")):
        continue  # strip legacy enrichment metadata
    cleaned.append(line)
notes = "\n".join(cleaned)
```

This ensures the digest script never has to clean stale metadata from old runs.

### Replacement Requisition Tracking
When a job is stale because the req ID changed but the role is identical:
- Mark original as `closed`
- Note the replacement req ID and URL in notes: `"Closed: YYYY-MM-DD (req OLD no longer active; replacement REQ found with same title/remote/pay range)"`
- Do NOT auto-create a new registry entry unless Maxime explicitly requests it

### Metrics Update Safety
`metrics.json` may store `maintenance_runs` as either a list or a scalar across different missions. Always read first and handle both:
```python
runs = metrics.get("job_registry_maintenance", [])
if isinstance(runs, list):
    runs.append({...})
else:
    metrics["job_registry_maintenance"] = [{...}]
```

## Verification
After enrichment:
- Salary range should match format: "\$\d+k-\$\d+k" or "Not disclosed"
- If notes were enriched, content should be clean (no timestamped metadata prefixes)
- Status should be either 'active' or 'closed'
- No stale enrichment metadata lines should remain

## Example Usage
See mission_job-registry-maintenance.md for full implementation.

---
**Linked Files:**
- templates/enrichment_patterns.md: Common regex patterns for salary/stale detection
- scripts/enrich_job.py: Reference implementation (if needed)