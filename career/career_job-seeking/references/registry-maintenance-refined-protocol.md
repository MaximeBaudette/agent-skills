# Registry Maintenance - Refined Verification Protocol

## Enhanced Cadence Calculation

Based on operational experience, refined cadence rules for job verification:

| Maxime Score | Cadence | Rationale |
|---|---|---|
| `null` (unrated) | Every 2 days | Default for new/unrated offers |
| `>= 4` (high interest) | Every 1 day | Critical offers need frequent verification |
| `2-3` (moderate interest) | Every 7 days | Standard review cycle |
| `0-1` (low interest) | Every 14 days | Minimal verification needed |
| `-1` (discarded) | Never | No verification required |

## Implementation Logic

```python
def get_cadence_days(maxime_score):
    if maxime_score is None:
        return 2  # every 2 days
    elif maxime_score >= 4:
        return 1  # every 1 day
    elif 2 <= maxime_score <= 3:
        return 7  # every 7 days
    elif 0 <= maxime_score <= 1:
        return 14  # every 14 days
    else:  # -1 or other negative
        return float('inf')  # never
```

## Batch Processing Strategy

- **Group URLs in batches of 5** to optimize web_extract calls
- **Process lowest cadence offers first** to prioritize critical items
- **Limit to 20 offers per run** to prevent rate limiting
- **Sort by cadence, then by days since verified**

## Verification Failure Handling

When web_extract fails:

1. **Check if URL is aggregator site** (jobleads.com, bebee.com, etc.)
   - If aggregator failure → mark as "stale"
   - Add explanatory note: "Aggregator site failed to fetch - likely stale"

2. **Check if URL is direct company careers site**
   - If direct site failure → attempt browser_navigate fallback
   - If browser_navigate unavailable → mark as "stale" with note

3. **Check for Cloudflare blocking**
   - If Cloudflare detected → note "Cloudflare verification blocked"
   - Do NOT mark as stale if content is accessible via other means

## Status Change Protocol

**NEVER** mark jobs as "closed" based solely on URL health checks. Only mark closed when:
- URL returns explicit "no longer accepting applications"
- Aggregator site returns 404 or "job expired"
- Multiple verification attempts fail AND no user activity exists

**ALWAYS** cross-check with:
- Job registry for interviews (`interview_scheduled`)
- User communications with employer
- Recent application activity

## Change Logging

Structure changes log with:
```json
{
  "date": "YYYY-MM-DD",
  "total_changes": N,
  "changes": [
    {
      "id": "offer_id",
      "type": "salary_enriched|status_changed|verified",
      "old_value": "...",
      "new_value": "...",
      "company": "Company Name",
      "title": "Job Title",
      "reason": "Explanation"
    }
  ],
  "verified_jobs": ["id1", "id2"],
  "stale_jobs": ["id3", "id4"],
  "salary_enriched": ["id5"]
}
```

## Error Patterns to Note

- **LinkedIn job URLs**: Often redirect to expired pages or show generic results
- **Aggregator sites**: Frequently blocked by Cloudflare or return empty content
- **Direct careers sites**: Most reliable for verification
- **Government jobs**: Often have stable URLs but may show "continuous posting" status

## Recovery from Over-correction

If status was incorrectly marked as closed:
1. Reverse the status change immediately
2. Add explanatory note: "Status reversed - URL health check was incorrect"
3. Log the reversal in changes log
4. Verify current status through alternative means if possible