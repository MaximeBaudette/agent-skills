# Job Board Scraping & Verification Patterns

## Platform-by-Platform Behaviour

### LinkedIn Job Pages
- Sign-in modal blocks JD content on first `browser_navigate`.
- Dismiss via button (usually `@e1`).
- Even with modal, the listing is live.
- **Primary signal extraction via `web_extract`:** Even when full JD is gated behind login, `web_extract` consistently returns three reliable active-status signals embedded in the LinkedIn UI shell:
  - `"Posted X days ago"` / `"Posted X weeks ago"` — confirms role was recently refreshed
  - `"Be among the first 25 applicants"` — confirms still accepting applications, fresh posting
  - `"No longer accepting applications"` — definitive closed signal (mark `closed` immediately)
  - LinkedIn job ID in the URL is canonical — if the page loads at all (even with sign-in modal), the listing is active
- **Dedup hazard:** LinkedIn job IDs are unique but the URL format in the registry may be stale. If `web_extract` on a LinkedIn URL returns content for a completely different company/role, the listing ID has been recycled by LinkedIn — treat as `needs_manual_check`.

### Tesla Careers (`tesla.com/careers/search/job/...`)
- `web_extract` → typically "Failed to fetch url".
- `browser_navigate` empty page / Access Denied.
- Fix: append `?source=careers`. If still empty, try base URL without params.
- Aggregator fallback (Ladders, Jobright.ai) if still blocked.

### TheLadders
- `web_extract` → "Failed to fetch url" (blocked headless).
- `browser_navigate` may load but truncated.
- Use `browser_vision` or `browser_scroll(direction="down")` to reveal full JD.
- Search aggregators if browser also blocked.

### iCIMS Career Portals (`*.icims.com`)
- JD lives inside iframe → `browser_snapshot` empty.
- `web_extract` works well as primary extraction method.
- Fallback: mark `active (unverified iframe)`.

### Schneider Electric Careers (`careers.se.com`)
- `browser_snapshot` and `web_extract` return mostly footer + anti-fraud boilerplate.
- `browser_navigate` loads heading + table rows (Job Category, Location, Req. ID) reliably.
- Treat as `needs_manual_check` if `browser_navigate` also fails.

### Climatebase (`climatebase.org`)
- `web_extract` WORKS reliably in most cases, returns structured markdown with company overview, salary context, and similar roles.
- Excellent for quick enrichment when employer site is gated.
- **⚠️ Timeout risk:** In some runs (observed 2026-05-08), Climatebase URLs timed out on `web_extract` even though the aggregator still lists the role. If it times out, **do not mark closed** — fall back to `web_search` (the role is often still live on LinkedIn). Climatebase listings are long-lived (2+ months not unusual) — if the page loads at all, the role is active.

### LBNL Careers (`jobs.lbl.gov`)
- `web_extract` returns FULL structured JD: responsibilities (detailed), mandatory requirements, desired qualifications, compensation, benefits, and company culture.
- Salary range is explicitly listed (e.g., `$180,000 – $198,000/year`).
- Posting includes work modality (onsite/hybrid/remote), PE license requirements, and application requisition ID.
- Postings persist for weeks to months — treat as reliable for both active verification and JD enrichment.
- No special workarounds needed.

### Vaia / Talents (`talents.vaia.com`)
- `web_extract` returns FULL structured JD content (responsibilities, compensation, qualifications, company profile).
- Excellent extraction quality — prefers Vaia's hosted version of employer JDs (e.g., Electric Hydrogen).
- No special workarounds needed; treat as reliable extraction source.

### GovernmentJobs (`governmentjobs.com`)
- `web_extract` returns rich structured content including full salary range, benefits, and job duties.
- Used by municipalities (City of Santa Clara, etc.) for public-sector postings.
- Posting URLs are stable across months — postings persist for many weeks.
- Treat as reliable extraction source.

### Lensa (`lensa.com`)
- `web_extract` returns comprehensive structured JDs with full responsibilities, qualifications, tools/tech stack, and company demographics.
- No special workarounds needed.
- Reliable for both active-status confirmation and salary/notes enrichment.

### GE Vernova Careers (`careers.gevernova.com`)
- `web_extract` returns EXCELLENT structured content: full role summary, responsibilities, qualifications, compensation (including geographic differentials), and application window dates.
- Application window dates (e.g., "April 7, 2026 – June 26, 2026") are first-class status indicators — if today is past the window, the role may still be active but should be verified.
- Treat as one of the most reliable extraction sources.

### Vestas Careers (`careers.vestas.com`)
- `web_extract` returns FULL structured JD: responsibilities, qualifications, compensation, relocation support, and company culture notes.
- One of the most complete extractions available — no workarounds needed.
- Also includes useful application guidance (e.g., "remove photos, DOB from CV").

### PG&E Careers (`careers.pge.com` / `jobs.pge.com`)
- **URL migration:** PG&E migrated from `jobs.pge.com` to `careers.pge.com`. Old-style URLs return 404. If a PG&E URL fails, search for the exact title + "PG&E" to find the migrated URL.
- `web_extract` works on `careers.pge.com` URLs (returns structured page with status indicator).
- A posting returning "not currently available" on the new domain means it's truly closed (not just a stale URL).

### Leidos / MyWorkdayJobs (`*.myworkdayjobs.com`)
- Cloudflare verification gates common.
- Mark `needs_manual_check`.
- Aggregator fallback: RemoteRocketship, Remotive for same req ID.

### IAWomen / Women's Career Channel (`careers.iawomen.com`, `womenscareerchannel.com`)
- Alternative aggregator network — often mirrors listings from Nextracker, Nextpower, and other energy/solar firms.
- `web_extract` returns FULL structured JD content (responsibilities, qualifications, salary context).
- Useful fallback when the primary aggregator (ZipRecruiter, TheLadders) or employer site blocks extraction.
- **Discovered 2026-05-09:** IAWomen confirmed Nextracker Staff Power System Interconnection Engineer role despite TheLadders blocking extraction entirely.
- **Discovery trigger:** When `web_extract` on ZipRecruiter or TheLadders fails → `web_search` the exact title + company → IAWomen/Women's Career Channel may be in results.

## General Decision Tree

1. Always try `web_extract` first (fastest, cleanest).
2. If empty/failed → try `browser_navigate`.
3. If blocked by modal → `browser_click(ref="@e1")` then `browser_snapshot(full=true)`.
4. If empty snapshot with 0 elements → retry with `?source=careers` or alternate URL params.
5. If still no content → `web_search` exact req ID for aggregator confirmation.
6. If aggregator confirms live within 7 days → mark active, note verification path.
7. If all paths blocked → mark `needs_manual_check`, log to `handoff_warnings.log`.

## Aggregator URL Decay Recovery

Aggregator URLs (JobLeads, RemoteRocketship, aggregator scrapers) frequently decay while the underlying role remains live.

**Trigger:** URL returns 404, "Failed to fetch url", or empty content.

**Recovery:**
1. `web_search(f'"{o.title}" "{o.company}" job site:linkedin.com OR site:{company_domain}', limit=3)`
2. Identify canonical posting (LinkedIn > company careers > specialized board)
3. Update `o.url` to the canonical URL
4. Log change as `type: "url_updated"`

**Known fragile aggregators:**
| Aggregator | Failure Mode | Recovery |
|---|---|---|
| JobLeads | URL hash expires, silent 404 | Search LinkedIn for role |
| Indeed search pages | URLs to search results (not direct JDs) | Find direct listing |
| Ladders / TheLadders | Blocks web_extract entirely | Try browser; if blocked, use search

## Batch Verification Without Browser (Preferred for Daily Maintenance)

As of May 2026, a pure `web_extract` + `web_search` pipeline can verify 20+ offers across diverse platforms without a single `browser_navigate` call. This is faster, more reliable, and avoids Camofox availability issues.

**Proven workflow (2026-05-08 run, 20 offers, 12+ platforms):**

```
Phase 1 — bulk web_extract (batches of 5 URLs):
  ├── LinkedIn → extract signals: "Posted X days ago", "Be among first 25", "No longer accepting"
  ├── Company careers (GE Vernova, Vestas, LBNL, Schneider) → extract full JD + salary
  ├── Aggregators (Lensa, Vaia, GovernmentJobs, RemoteRocketship) → full structured content
  ├── iCIMS portals → page loads confirm active (JD in iframe — still reliable)
  └── Blocked: Tesla, TheLadders, MyWorkdayJobs, sometimes Climatebase → empty/failed/timed out

Phase 2 — web_search fallback (for Phase 1 failures):
  ├── Query pattern: `"{exact title}" "{company}" job site:linkedin.com`
  ├── Check results for: "applies 1-25", "posted X days ago", employer career page still listing req ID
  ├── Tesla: search by req ID + company — if "Apply" page shows Step 1 of 3, role is active
  ├── MyWorkdayJobs: aggregator fallback (RemoteRocketship, Remotive) confirms active
  └── Climatebase timeout: search LinkedIn for same title + company
```

**Decision matrix for Phase 2 results:**

| Search result signal | Interpretation |
|---|---|
| LinkedIn shows "Posted X days ago" + "<25 applicants" | Active, fresh posting |
| LinkedIn shows "No longer accepting applications" | Closed immediately |
| Tesla careers shows "Step 1 of 3" (application page active) | Active |
| Aggregator (Remotive, RemoteRocketship) shows role listed within last month | Active (for Cloudflare-blocked employers) |
| No results found on any platform | Needs manual check |

**Resource efficiency:** 20 offers → ~4 `web_extract` calls (batches of 5) + ~4 `web_search` calls = ~8 total tool calls, ~2-3 minutes wall time. Compare to 20 `browser_navigate` calls requiring Camofox at ~15+ minutes.

**When browser_navigate IS still needed:**
- Reading JDs for enrichment (notes/salary extraction from blocked sites)
- Verifying offers with no aggregator presence
- Sites where web_extract returns insufficient content (Schneider careers, some TheLadders pages)
