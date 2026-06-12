# Mission: Job Hunt

**CRON TEMPLATE FALLBACK GUARD:** If your prompt contains literal `{{mission}}` or `{{skill}}` (the generic "Execute the active mission..." template), follow `references/cron-template-variable-resolution.md` **exactly** to deduce this is Job Hunt (Mon 6:30am schedule) and load this file via `skill_view(name='career_job-seeking', file_path='mission_job-hunt.md')`. Then follow this spec's phases precisely. Never improvise.

**Trigger:** cron Mon 6:30am PT (id 0c12bc1fd39e) | "run job hunt" | "find jobs"

**Startup Check:**
1. Verify idempotency flag memory/weekly/YYYY-MM-DD_digest_sent.flag absent. If exists + manual -> ask override; if cron -> [SILENT] stop.
2. Pre-flight: run Google OAuth health check per SKILL.md. Fail -> STOP, escalate.
3. Read feedback (unapplied) and learned_prefs.md (active) -> apply in-memory.
4. Load profile per AGENTS.md and job_registry.json. Save startup_unreviewed_count.

**Procedure:**
1. Phase 1 (Tier 1): 5 web_search queries for Oakland/East Bay/Remote. Per result: extract, score 1-10 per rubric, dedup against registry, tier=1. Save weekly/YYYY-MM-DD_local.json.
2. Phase 2 (Tier 2): Same for Bay Area. tier=2. Save weekly/YYYY-MM-DD_regional.json.
3. Phase 3 (Tier 3): Same for relocation (LA/SD/SLC/Austin). score >=7 only. Save weekly/YYYY-MM-DD_relocation.json.
4. Phase 4 (Digest): Run Phase 5 (aggregate skills from high-scoring offers, 2 market trend searches) inline. Execute generate_digest.py. Write flag + thread. On skipped_no_offers with startup_unreviewed_count==0 -> [SILENT] stop.
5. Phase 5 (Signals): Aggregate skills from high-scoring offers. 2 market trend searches. Write profile_signals.json. Include postscript if suggestions.
6. Phase 6 (Reply): Parse Maxime SCORES:/FEEDBACK: from digest reply. Update job_registry.json. Write job_hunt_flagged.json. Archive thread.

**Scoring Rubric (1-10):** 10=perfect (target role + core tech + Tier1 + salary>=150k + senior). 8=strong (one gap). 5=adjacent field. <=2=deal-breaker (oil/gas, clearance, salary<130k).

**Registry Dedup:** URL new -> add (increment last_id). URL existing + maxime_score null -> resurface. URL existing + maxime_score set -> skip.

**Output:** Updated job_registry.json, email digest, job_hunt_flagged.json, profile_signals.json, metrics.json

**Edge Cases:**
- Flag exists + cron -> [SILENT] skip. Manual -> ask override.
- Profile not found -> default queries, log warning.
- Email send fails -> do not mark sent, return error.
- Phase 6: thread not found -> ask Maxime to forward.
- Phase 6: registry write fails -> do NOT archive thread until success.
- Post-application entries: NEVER validate URLs. See SKILL.md lifecycle rule.
