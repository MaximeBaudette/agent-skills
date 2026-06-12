# Mission: Job Registry Maintenance

**CRON TEMPLATE FALLBACK GUARD:** If your prompt contains literal `{{mission}}` or `{{skill}}` (the generic "Execute the active mission..." template), follow `references/cron-template-variable-resolution.md` **exactly** to deduce this is Registry Maintenance (daily 6:20am schedule) and load this file via `skill_view(name='career_job-seeking', file_path='mission_job-registry-maintenance.md')`. Then follow this spec's phases precisely. Never improvise.

**Trigger:** cron daily 6am PT | "tidy registry" | "validate offers"

**Startup Check:**
1. Load memory/job_registry.json, validate JSON structure.
2. Load profile per AGENTS.md for salary targets.

**Procedure:**
1. Filter for status==active only. Apply verification cadence by maxime_score: null -> every 2d, 4+ -> every 1d, 2-3 -> every 7d, 0-1 -> every 14d, -1 -> never.
2. Skip offers where last_verified_date < cadence_days. Prioritize lowest cadence first. Limit 20 per run.
3. **Parallel verification (optimized):** Collect all qualifying URLs into a single list. Call `web_extract([url1, url2, ..., urlN])` ONCE with the full batch (max 20 URLs) — the tool processes them in parallel internally. This eliminates the 600s idle timeout from sequential loops.
4. For each resolved URL, check stale markers (404 text, "no longer available", "filled", "closed"). Mark status=closed if stale.
5. For any URL where web_extract returns empty/error: use `web_search` as fallback — search for exact job title + company + req_id to find live listing or confirm dead. If neither original nor search confirms alive, mark status=closed.
6. Fallback to `browser_navigate` only for Cloudflare-gated sites (max 2 per run).
7. Enrich: if salary_range missing/"Not disclosed", web_search levels.fyi/glassdoor. If notes empty, extract JD summary.
8. Write updated job_registry.json + memory/logs/registry_maintenance/YYYY-MM-DD_changes.json.
9. If changes > 0: send Telegram summary.

**Output:** Updated job_registry.json, changes log, Telegram summary (if changes)

**Edge Cases:**
- web_extract empty -> browser_navigate fallback for blocked sites only.
- No credible salary source -> leave as-is.
- >20 qualifying offers -> process top 20, log "throttled".
- Post-application entries (applied+): SKIP entirely. URL health is irrelevant after application.
- Platform-specific quirks: see references/registry-maintenance-practical-patterns.md
- Cron: [SILENT] if no changes; error report only on failure.
