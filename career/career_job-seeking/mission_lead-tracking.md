# Mission: Lead Tracking

**CRON / UNRESOLVED TEMPLATE FALLBACK GUARD (READ THIS FIRST ON EVERY INVOCATION)**

If the prompt you received contains the literal text `{{mission}}`, `{{skill}}`, or the generic sentence "Execute the active mission: {{mission}}...", this is a template resolution failure in the cron definition.

**You MUST:**
- Immediately follow the exact mandatory recovery procedure in `references/cron-template-variable-resolution.md`.
- Deduce this is the Lead Tracking cron (schedule `0 9,13 * * *`, job name "Job-Search: Lead Tracking").
- Load this file **using** `skill_view(name='career_job-seeking', file_path='mission_lead-tracking.md')`.
- Then execute **only** the Procedure below, respecting every phase, confirmation rule, edge case, and the current data state (handoff files present? interviews already inline? etc.).
- **Never improvise** phases, run unrelated logic (e.g. Phase 8 onboarding unless this spec explicitly directs it for the present context), or make up data mutations. Past butchered runs were caused by exactly this.

After loading, re-read the Startup Check and Procedure. The spec here is the law.

---

**Trigger:** Post Job Hunt reply processing | "show pipeline" | "let's apply to #ID"

**Startup Check:**
1. Read memory/feedback/lead_tracking_feedback.json (unapplied) -> apply in-memory.
2. Read memory/feedback/learned_prefs.md (active entries for lead_tracking/all) -> apply.

## Procedure:

1. Phase 0 (High-Score Reminder): Scan job_registry.json for maxime_score>=4, status==active, last_verified_date>7d ago. Send Telegram reminder for each.
2. Phase 1 (Ingest): Load memory/handoffs/job_hunt_flagged.json. Add ingested==false entries (maxime_score>=1) to job_leads.json, status=preparing. Mark ingested=true.
3. Phase 2 (Pipeline Update): Compute days_since_last_action for all non-terminal entries. Flag stale (>7d). Report to Maxime. Apply status updates.
4. Phase 3 (Application): Read JD via browser. Load profile per AGENTS.md. Generate CV tailoring notes + cover letter. Save to career/leads/<date>_<company>_<role>/. Set status=ready_to_apply. CONFIRMATION REQUIRED before sending.
5. Phase 4 (Follow-up): If applied>7d no response -> draft follow-up email. CONFIRMATION REQUIRED to send.
6. Phase 5 (Interview Handoff): When status->interview_scheduled, embed interviews array in job_leads.json entry. Notify Maxime.
7. Phase 6 (Queries): Natural language queries against registry/pipeline: "show preparing", "show tier 1", "show score 5", "show #ID", "discard #ID", etc.
8. Phase 7 (Health): Compute pipeline metrics (conversion rate, days since last lead, etc.). Alert on thresholds. Update metrics.json.
9. **Phase 8 (Onboarding Tracker):** Scan job_leads.json for status=="accepted" or "offer_accepted". For each: if acceptance >5d and no start_date/onboarding_notes documented, flag to Maxime (principal gap = offer accepted but start logistics missing). Skip if employment_status already updated to "employed".

**Status Lifecycle:** preparing -> ready_to_apply -> applied -> screening -> interview_scheduled -> offer. All can -> rejected or withdrawn.

**Output:** Updated job_leads.json, marked ingested in job_hunt_flagged.json, metrics.json

**Edge Cases:**
- No handoff file -> skip Phase 1.
- Multiple interview_scheduled -> list for Maxime to pick.
- 21d no-new-leads -> alert Maxime.
- JD URL unavailable or browser fails -> try web_extract fallback, else skip Phase 3.
- Post-application: NEVER verify URLs. Status only via employer or Maxime.
