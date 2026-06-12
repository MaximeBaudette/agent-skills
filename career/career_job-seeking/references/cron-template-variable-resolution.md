# Cron Template Variable Resolution Fallback

**🚨 CRITICAL — DO NOT IMPROVISE**

**Problem:** Career-manager cron jobs use `{{mission}}` template variables in their prompts. When the cron scheduler does not resolve these variables (no template engine or variable never hydrated), the prompt will contain the literal string `"Execute the active mission: {{mission}}."` — which is not actionable.

**HARD RULE:** If your incoming user/cron prompt contains the literal text `{{mission}}` or `{{skill}}` (or the exact generic sentence "Execute the active mission: {{mission}}..."), you are in **fallback mode**. You MUST stop, follow this document's recovery procedure to the letter, load the correct mission via `skill_view`, and execute **only** the documented phases for the deduced mission. Improvising the procedure, guessing phases, running unrelated phases (e.g. Onboarding Tracker during a routine Lead Tracking slot), or mutating data without the exact spec is a process violation and the cause of past butchered runs (e.g. Lead Tracking 2026-06-07+).

The correct long-term fix is explicit prompts in the cron job definitions (see "Resolution" below and the updated jobs in the ref bundle). Until all live cron jobs are updated, this fallback is your only safe path.

## Detection

When a cron session starts, check the prompt for unresolved template variables:

| Pattern | Status |
|---------|--------|
| Literal `{{mission}}` in instruction | ❌ Template NOT resolved — need fallback |
| Literal `{{skill}}` in instruction | ❌ Template NOT resolved — need fallback |
| Explicit mission name (e.g., "Lead Tracking") | ✅ Template resolved — proceed normally |

## Recovery: Determine Which Mission to Run (MANDATORY PROCEDURE)

When you detect literal `{{mission}}` or `{{skill}}` (or the generic "Execute the active mission: {{mission}}..." text), you **MUST** execute this procedure exactly. No shortcuts, no improvisation.

1. **Immediately read the live cron jobs definition** (do not proceed with any mission work yet):
   `file` tool on `~/.hermes/profiles/career-manager/cron/jobs.json` (or the full path under the profile).

2. **Identify the triggering job** by best match (be precise; multiple jobs share similar times):
   - Compare current wall time (use timezone America/Los_Angeles) to every job's `schedule.expr`.
   - Look at `last_run_at` (the one whose last_run is most recent and whose schedule matches the current slot).
   - Look at `next_run_at`.
   - Use the job's `name` and `id` as tie-breakers.
   - Cross-check against the table below.

3. **Deduce the exact mission** from this table (the source of truth for fallback):

| Schedule expr       | Cron Job Name              | Mission Name        | File to load via skill_view                          |
|---------------------|----------------------------|---------------------|------------------------------------------------------|
| `20 6 * * *`        | Job-Search: Registry Maintenance | Registry Maintenance | `mission_job-registry-maintenance.md` |
| `0 9,13 * * *`      | Job-Search: Lead Tracking      | Lead Tracking       | `mission_lead-tracking.md`            |
| `30 6 * * 1`        | Job-Search: Weekly Hunt        | Job Hunt            | `mission_job-hunt.md`                 |
| `0 6 1 * *`         | Employment: Monthly Optimizer  | (employment-optimizer skill gate handles it) | N/A (different skill) |

4. **Load the mission spec as the single source of truth**:
   Use the tool call: `skill_view(name='career_job-seeking', file_path='<the file from table>')`.
   Read the entire loaded content. Do **not** rely on previously cached knowledge or other references for the step-by-step.

5. **Execute ONLY the phases and rules in the loaded mission spec** for the current invocation context (presence/absence of handoff files like `job_hunt_flagged.json`, current state of `job_leads.json` / `job_registry.json`, any user message that accompanied the cron).
   - Follow the numbered Procedure phases in order.
   - Respect all "CONFIRMATION REQUIRED", "Startup Check", edge cases, and output contracts in the spec.
   - Before any write to job_* data, re-read `references/boundary-violations.md` and the RECORD-BEFORE-REPLY rule from workspace/AGENTS.md.
   - At the end, produce output per `references/cron-output-format.md`.

6. **Log the fallback**: At the very end of the run (or in memory/feedback), note that this was a template-unresolved invocation and which job/schedule you deduced.

**Never**:
- Guess or "improvise" a reasonable-sounding procedure.
- Run phases from a different mission (e.g. onboarding Phase 8 during Lead Tracking unless the Lead Tracking spec explicitly says to in this context).
- Mutate data "to be helpful" outside the exact spec.
- Skip reading the live jobs.json because "I think I know the schedules".

## Why This Happens

The `{{mission}}` template places a variable in the cron prompt that the scheduler should expand on each run. If the scheduler lacks template expansion support, or if the variable name doesn't match any registered template function, the literal text passes through.

This is distinct from the file-path resolution issue documented in `references/cron-troubleshooting.md`. That reference covers `read_file` vs `skill_view` for loading mission files from relative paths. This issue is about variable expansion in the prompt itself — the prompt never told the agent which mission to run.

## Jobs Affected

All three `career_job-seeking` cron jobs in this profile use unresolved `{{mission}}`:

| Job | ID | Schedule | Mission |
|-----|-----|----------|---------|
| Weekly Hunt | `0c12bc1fd39e` | Mon 6:30am | Job Hunt |
| Registry Maintenance | `d0c84c0cbb3e` | Daily 6:20am | Registry Maintenance |
| Lead Tracking | `6929265c8a64` | Daily 9am, 1pm | Lead Tracking |

## Resolution Preference

If you have access to edit cron job prompts (e.g., via `cronjob` tool), replacing `{{mission}}` with an explicit mission name eliminates the dependency on template resolution. However, per AGENTS.md, config changes require Maxime's explicit approval — do not edit cron prompts autonomously.

## Applied / Incidents

- **2026-06-05:** Lead Tracking cron fired at 9am PT with unresolved `{{mission}}`. Deduced from schedule. (Example in prior version of this doc.)
- **2026-06-07 (and subsequent 9am/1pm slots):** Lead Tracking cron(s) received literal `{{mission}}` / `{{skill}}` template. Agent reported the exact generic prompt and stated he "improvised". This directly caused butchered lead tracking runs (incorrect phase selection, improper mutations to `job_leads.json` / registry / handoffs, skipped or wrong ingestion, etc.). Root cause: live cron job definitions still carried the unresolved template prompt (see `MARS/andy/crons/jobs.json` ref and live `~/.hermes/profiles/career-manager/cron/jobs.json`).
- **Fix applied in ref bundle (2026-06-11):** Updated the three `career_job-seeking` cron prompts in `MARS/andy/crons/jobs.json` (Weekly Hunt, Registry Maintenance, Lead Tracking) to be fully explicit: they now hardcode the mission name + `skill_view(name='career_job-seeking', file_path='mission_....md')` + "follow EXACTLY" + "never improvise" language. This matches the recommendation in `references/cron-troubleshooting.md`. 
- **Next required:** Update the *live* Hermes cron job definitions on mars (via `cronjob` tool or equivalent `hermes cron` management) using the new prompt text from the ref bundle's jobs.json. Do not let the agent perform the cron config change without your explicit approval + diff review. After live update, re-pull `MARS/andy/` and verify the jobs.json copy. 

Until the live jobs are updated with the explicit prompts, treat any cron prompt containing the old generic template as a signal to run the mandatory recovery above.
