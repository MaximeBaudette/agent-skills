# Cloudflare Blocking: Camofox Unavailable

**Problem:** When `web_extract` fails due to Cloudflare blocking and `browser_navigate` is also not available (Camofox server not running), cannot verify job posting status directly.

**Symptoms:**
- `web_extract` returns empty content or error for certain sites
- `browser_navigate` fails with "Cannot connect to Camofox at http://localhost:9377"
- Sites like Leidos, ZipRecruiter, and others with Cloudflare protection

**Solution (DO NOT mark as closed):**
1. **Mark as "stale"** - NOT "closed" - per URL health check rules
2. Add explanatory notes: `"Cloudflare blocked, cannot verify; aggregator link"` or `"Cloudflare blocked verification error"`
3. Preserve status if external signals suggest listing is still active

**Critical Protocol:**
- **NEVER** mark jobs as "closed" based on verification blockages
- Use "stale" status to indicate verification limitations
- Only mark as "closed" when you have definitive evidence (404, explicit "no longer available", etc.)
- This prevents pipeline corruption from false negatives

**Example handling:**
```python
# Instead of marking as "closed":
offer['status'] = 'stale'
offer['notes'] = f"{existing_notes}\nStale: {today} (Cloudflare blocked, cannot verify; aggregator link)"
```

**When to use this:** Any time automated verification fails due to technical barriers (Cloudflare, bot detection, service unavailability) rather than definitive job closure signals.

**Session Example (2026-05-25):**
- Offers #065 (Leidos) and #066 (Nextracker) encountered Cloudflare blocking
- Both marked as "stale" with explanatory notes
- Status preserved to avoid false closure signals