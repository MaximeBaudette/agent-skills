# Registry Maintenance — Gaps & Patterns (Discovered 2026-05-05)

Captures learnings from maintenance runs that don't yet live in `mission_job-registry-maintenance.md`.

---

## 1. Missing `status` Field on New Offers

**Symptom:** Offers discovered by Job Hunt Phase 6 (IDs #070–#075) arrive without a `status` field. The FILTER step in the mission spec only catches `status == 'active'`, so these offers are silently skipped.

**Fix — execute after loading registry, before FILTER:**
```python
missing_status = [o for o in registry.offers if 'status' not in o]
for o in missing_status:
    o['status'] = 'active'
# Log each one as a change entry: type="status_assigned"
```

**Root cause:** Job Hunt Phase 6 doesn't set `status` on newly created offer entries. Until that's fixed, this STARTUP cleanup is mandatory.

---

## 2. Browser Unavailability Fallback

**Symptom:** Camofox / browser tool (`browser_navigate`) is sometimes down. The mission spec lists no fallback path.

**Recovery — tiered verification:**
1. **Preferred:** `web_extract([url])` — works for LinkedIn (shell), Lensa, Climatebase, iCIMS, most aggregators
2. **Fallback:** `web_search` for the exact job title + company + req ID — check aggregator results for "No longer accepting applications" signals
3. **Last resort:** If both fail and `last_verified_date` is < 7 days old, leave as-is (it was fine last week)

---

## 3. Salary Enrichment — Proven Sources

The mission spec mentions levels.fyi and glassdoor. These additional sources consistently return useful data:

| Source | Best For | Query Pattern |
|---|---|---|
| **Glassdoor** | Employer-provided ranges (most reliable) | `"{title}" {company} glassdoor salary` |
| **Lensa** | Aggregated estimates + contract rates | `{company} {title} salary site:lensa.com` |
| **ZipRecruiter** | Employer-listed ranges | `"{title}" "{company}" site:ziprecruiter.com` |
| **Indeed** | Crowdsourced averages | `{company} {title} site:indeed.com` |

**Decision rule:** Take Glassdoor employer-provided > ZipRecruiter employer-listed > Lensa estimate > Indeed crowd avg. If the range spans the $150K floor, include it regardless of low end.

---

## 4. Batch Registry Updates via Python (Preferred)

For registry files spanning 1000+ lines (1169 lines as of May 2026), individual `file` patching is error-prone and slow. Use `execute_code` with Python's `json` module instead:

```python
import json

path = "/home/mars/.hermes/profiles/career-manager/workspace/memory/job_registry.json"
with open(path) as f:
    registry = json.load(f)

# Index by ID for easy lookup
offer_map = {o["id"]: o for o in registry["offers"]}

# Make changes...
o = offer_map["070"]
o["status"] = "active"
o["salary_range"] = "$160,000-$175,000"

# Write back
with open(path, 'w') as f:
    json.dump(registry, f, indent=2)
```

**Caveat:** Avoid for one-off typo fixes or single-field changes — `file` patching is faster for those. Reserve Python for bulk operations (3+ changes or structural modifications like adding missing fields).

---

## 5. Metrics Update Pattern

When writing maintenance results to `metrics.json`, always `metrics["job_registry_maintenance"].append(...)` — do NOT overwrite. The last run (2026-05-03) and this run (2026-05-05) both used append successfully.

---

## 6. Company URL Migration Detection

**Symptom:** A listing URL returns 404, but the role still exists on a different URL.

**Example:** PG&E migrated from `jobs.pge.com` to `careers.pge.com`. The original URL for #007 returned 404, but a `web_search` for the exact title + "PG&E" found the new URL on the new domain (though the posting was ultimately inactive).

**Procedure when URL returns 404:**
1. Do NOT immediately mark `closed`. Search for the exact title + company first.
2. `web_search(f'"{o.title}" "{o.company}" job {o.location}', limit=3)`
3. Check if result links are on a different domain (e.g., `jobs.pge.com` → `careers.pge.com`)
4. If found on same company domain, the URL migrated — update `o.url` and verify the new URL
5. If the new URL also shows the role as inactive, THEN mark closed
6. Log as `url_migrated` in the change log if URL was updated

---

## 7. Aggregator URL Decay Recovery

**Symptom:** An aggregator URL (JobLeads, aggregator scrapers) returns HTTP 404 or "Failed to fetch url", but the actual job role is still live on the employer's site or LinkedIn.

**Example:** #012's JobLeads URL failed, but `web_search` for the exact role title + company found the live LinkedIn posting (active 3 days ago, <25 applicants).

**Procedure when aggregator URL fails:**
1. `web_search(f'"{o.title}" "{o.company}" job site:linkedin.com OR site:{company_domain}', limit=3)`
2. If multiple results show the same role:
   - Pick the most authoritative source (LinkedIn > company careers > aggregator)
   - Update `o.url` to the canonical posting
   - Log a change entry with `type: "url_updated"` and reason describing the recovery
3. If no results show the role on a primary source, check Glassdoor/Indeed to distinguish "URL changed" from "role closed"
4. Only mark `closed` if no active posting is found on any primary source

---

## 8. Status Naming Convention

**Discovered inconsistency:** The `mission_job-registry-maintenance.md` spec says to set `status='stale'`, but the actual registry data and all downstream code use `status='closed'`. The change log type field uses `"stale"` to describe the type of change.

**Rule:**
- Registry `status` field → use `'closed'` (not `'stale'`)
- Change log `type` field → use `"stale"` (describes what happened)
- This matches existing convention in all previous maintenance runs

---

## 9. Shortlisted Offers Need Verification

**Discovered:** The mission spec's FILTER only checks `status == 'active'`, but shortlisted offers also expire. Both closed offers found in the 2026-05-06 run (#001 ICF, #007 PG&E) had status `shortlisted`.

**Procedure:** When filtering offers to check, include both `active` and `shortlisted` statuses. Add a note to each shortlisted offer after verification noting whether it's still live.

---

## 10. URL Health Check Over-correction Violation (2026-05-25)

**CRITICAL PATTERN:** Agent incorrectly marked job as "rejected" based on automated URL health checks, when user had actually secured interview.

### Symptom
- Job posting URL returns 404 or "No longer accepting applications" 
- Agent automatically updates status to "rejected" or "closed"
- User actually has interview scheduled or has been contacted by employer
- Pipeline status becomes incorrect, causing confusion and missed opportunities

### Root Cause
- Agent over-reliance on automated signals without verifying user context
- Violates explicit hard rule: "Post-application: NO URL health checks. Status only via employer or Maxime."
- No cross-check with user communications or scheduled interviews

### Prevention Protocol

**DO NOT:**
- ❌ Mark job as "rejected" or "closed" based on URL health checks alone
- ❌ Update status without cross-referencing user context

**INSTEAD:**
1. ✅ Check job registry for existing interview status (`interview_scheduled`, `contact_made`)
2. ✅ Check user communications for any employer contact
3. ✅ If interview scheduled → LEAVE STATUS AS IS, add note explaining URL failure but interview confirmation
4. ✅ If employer contact → LEAVE STATUS AS IS, add note explaining URL failure but ongoing communication
5. ✅ Only mark as closed if NO user activity and NO interview scheduled

### Recovery Protocol
If this violation occurs:
1. **Immediate Reversal:** Revert status back to pre-violation state
2. **User Notification:** Explain reversal and reason
3. **Note Addition:** Document override and source of confirmation
4. **Pattern Logging:** Document in memory to prevent recurrence

### Hard Rule Reinforcement
**MEMORIZE:** "URL health checks are INVALID after application. Status only changes via employer direct communication or user instruction. Never trust automated signals over user context."
