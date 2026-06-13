# Registry Maintenance — Practical Batch Verification Patterns

**Context:** When Camofox browser is unavailable, offers can still be verified efficiently using batch `web_extract` + `web_search`. This file documents the platform-specific patterns that work (confirmed during 2026-05-10 run — 25 offers verified in ~10 tool calls).

---

## Batch Strategy

- **Primary (parallel):** `web_extract([url1, url2, ..., urlN])` with ALL qualifying URLs in one call (max 20). The tool processes them in parallel internally — this is ~10x faster than sequential batches and avoids the 600s cron timeout. Verified working for: LinkedIn, Lensa, Climatebase, iCIMS, GE Vernova, Vestas, governmentjobs.com, Vaia/Talents, RemoteRocketship
- **Fallback for blocked platforms:** `web_search(query, limit=3)` with exact title + company + req ID
- **Leave-as-is threshold:** If `last_verified_date` < 7 days old and both methods fail, skip (verified recently)

---

## Platform-Specific Patterns

| Platform | web_extract? | web_search? | Notes |
|---|---|---|---|
| **LinkedIn** | ✅ Returns UI metadata + applicant count | N/A | Confirms post is active via "Be among first 25 applicants" / "1 week ago" / "55 applicants". Full JD gated behind login. |
| **Tesla** (`tesla.com/careers`) | ❌ Blocked (bot protection) | ✅ Confirmed via JobzMall, Jobright.ai, Ladders, h1b-connect.com, or Tesla's own application page at `/careers/search/job/apply/{req_id}` | Search for `"tesla" "{title}" {req_id} career` |
| **TheLadders** | ❌ Blocked (headless detection) | ✅ Confirmed via TheLadders own search results or Jobright.ai | Search: `site:theladders.com "{title}" "{company}" "{ladders_id}"` |
| **iCIMS** (`*.icims.com`) | ✅ Returns full JD | N/A | Confirmed for S&L and EPE iCIMS portals |
| **ZipRecruiter** | ❌ Cloudflare block | ✅ Confirmed via TalentAlly, Women's Career Channel, or ZipRecruiter cached results | Search: `"{title}" "{company}" "{location}" 2026` |
| **Leidos / Workday** (`*.myworkdayjobs.com`, `careers.leidos.com`) | ❌ Cloudflare block | ✅ Confirmed via RemoteRocketship, VetJobs, JobLeads | Search: `"R-{req_id}" Leidos "{title}"` |
| **Schneider Electric** (`careers.se.com`) | ❌ Navigation chrome only (JS-rendered JD) | N/A | Page load confirms listing is live; JD itself not extractable without browser |
| **GE Vernova** (`careers.gevernova.com`) | ✅ Full JD | N/A | Works reliably |
| **Vestas** (`careers.vestas.com`) | ✅ Full JD | N/A | Works reliably |
| **Climatebase** | ✅ Full structured content | N/A | Works reliably; good for enrichment too |
| **GovernmentJobs** (`governmentjobs.com`) | ✅ Full content | N/A | Works reliably |
| **Lensa** | ✅ Full JD | N/A | Works reliably |
| **RemoteRocketship** | ✅ Full JD | N/A | Works reliably |
| **Vaia/Talents** | ✅ Full JD | N/A | Works reliably |

---

## Aggregator Search Queries That Work

For blocked platforms, these web_search queries consistently find active listing confirmations:

```text
# Tesla
"tesla" "{title}" {req_id} career
# Example: "tesla" "sr system integration engineer" "industrial energy products" 251090 career

# TheLadders listing
site:theladders.com "{title}" "{company}" "{ladders_id}"
# Example: site:theladders.com "staff power system interconnection engineer" "nextracker" "83225704"

# Leidos by req ID
"R-{req_id}" Leidos "{title}"
# Example: "R-00178046" Leidos "Lead Microgrid Engineer"

# ZipRecruiter / Nextracker
"{title}" "{company}" Fremont 2026
```

---

## Enrichment Notes

During registry maintenance, skip enrichment for offers that already have salary_range and notes. Focus verification effort on:
- Offers with `last_verified_date` > 7 days old
- Offers with `status == 'shortlisted'` (they expire too — check them alongside active)
- Offers with empty `salary_range` or `notes`
