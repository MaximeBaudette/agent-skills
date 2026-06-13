# Interview Coach — JD Recovery from Aggregators & HR Screen Tuning

## Problem

During Interview Coach Phase 1, the JD URL from `job_leads.json` may return 404 — common after:
- Company acquisitions (ATS migration, URL restructuring)
- Role reposted under a new ID
- Lever.co URL removed post-acquisition

**Do not skip Phase 2 role research if the URL is dead.**

## Tiered JD Recovery

### Tier 1 — Direct aggregator scan (fastest)

Run `web_extract` on these sites, searching for the exact title + company:

| Aggregator | Notes |
|---|---|
| `talents.vaia.com` | Often caches full JD text with responsibilities, requirements, salary |
| `pitchmeai.com` | Good for Intersect/Google roles; preserves JD with benefits detail |
| `bebee.com` | Cross-posting aggregator, often has salary and full JD |
| `ziprecruiter.com` | Lists salary ranges and skill breakdowns |
| `climatebase.org` | Strong for clean energy roles; has company overview + JD |
| `remote.co` | Good for remote roles; checks company remote culture |
| `indeed.com` | Use web_search + "site:indeed.com" for exact title + company |
| `glassdoor.com` | Interview questions and process from candidates |

Search pattern: `web_search("exact title company")` then try `web_extract` on each result.

### Tier 2 — Lever.co specific

If the original URL was `jobs.lever.co/<company>/<id>`:
1. Try the URL with different query params removed
2. Search `"<company>" "lever.co" "<role_title_fragment>"` — may find the new URL if the role was migrated
3. Check if the company moved from Lever to another ATS (Greenhouse, Workday, etc.)

### Tier 3 — Notes fallback

Use the `notes` field from `job_leads.json` or `job_registry.json` entries. If a previous JD summary was generated (by Job Registry Maintenance or a prior run), reconstruct the role context from it.

## Post-Application 404 Rule

Per the post-application lifecycle rule: **a 404 on a URL for an active interview lead does NOT mean the role closed.** The JD may have been removed because:
- The listing was reposted under a new ATS
- Post-acquisition, the company moved to the acquirer's ATS
- The listing aged out and was refreshed

Use aggregator recovery first. Never flag a 404 as "role closed" when the lead has `status: interview_scheduled`.

## HR Screen vs Technical Interview Tuning

The Interview Coach mission's Phase 2-6 output is calibrated for technical interviews. When `interview_format` is `phone_screen` or involves a recruiter/HR contact, **tint the output**:

### What to deprioritize
- Heavy technical question bank (4a) — skip or keep to 3 max light ones
- Deep STAR story mapping — save full stories for the hiring manager round
- Negotiation deep dive — save salary specifics for offer stage

### What to prioritize
- **Company snapshot** — make it excellent: recent news, acquisition context, what problem they solve (the recruiter will ask "what do you know about us?")
- **Why leaving / why this role** — the most important screen question. Have a tight 30-second narrative
- **Salary alignment** — know the published range and have a number ready if asked
- **Process timeline** — ask the recruiter what to expect next
- **Logistics** — confirm time, format, who you'll meet, what to prepare
- **2-3 smart questions** — focused on team, culture, and next steps (not technical depth)
- **Background red flags** — be ready for "why leaving LBNL?" and "research to industry transition"
