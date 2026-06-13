---
name: manual_cron_trigger_troubleshooting
description: How to manually trigger a Hermes cron job when scripts are missing or paths are uncertain. Includes steps for locating job definitions, inspecting handoff files, using cronjob list/run, handling missing scripts, and verifying ingestion.
tags:
  - career
  - troubleshooting
  - cron
version: 1.2
author: Andy
---

# Manual Cron Job Trigger Troubleshooting

When a scheduled job needs to be run outside of its cron schedule (e.g., for debugging or immediate execution), follow these steps:

1. **List all cron jobs** to identify the target job ID and preview.  
   ``` 
   cronjob action='list'
   ```

2. **Inspect the job definition** to understand the associated skill/mission.  
   - Look at `prompt_preview`, `skill`, `schedule`, etc.

3. **Verify required scripts and files**:  
   - Check `career/skills/.../scripts/` for expected helpers.  
   - If a script is missing, locate the relevant payload (e.g., `generate_digest.py`).

4. **Search for missing files** if they are not where expected.  
   - Use `search_files` with appropriate patterns.  
   - Confirm file paths relative to `HERMES_HOME`.

5. **Run the cron job manually**:  
   - `cronjob action='run' job_id='<job_id>'`  
   - Observe the response for success or errors.

6. **Handle missing or renamed scripts**:  
   - If a script is not found, check for alternate names or recent changes.  
   - Use `execute_code` or direct file reads to confirm content.  
   - Create or patch the missing script if it is part of the expected workflow.

7. **Confirm pipeline state**:  
   - Check `memory/metrics.json` or relevant handoff files.  
   - Ensure ingestion completed (entries removed from `job_hunt_flagged_pending.json`) before proceeding.

8. **Iterate and troubleshoot**:  
   - If errors appear, review logs (`memory/logs/audit.log`).  
   - Adjust search patterns or file paths accordingly.

*Tip:* Keep a snippet of common `search_files` patterns for mission-related scripts:
```python
search_files(pattern="generate_digest.py", target="files", path=".")
```

This approach was used on 2026-04-08 to manually trigger the weekly job hunt after discovering `generate_digest.py` was missing, requiring script location, path verification, and direct job execution via cronjob.

---

## Mission File Path Resolution (Cron Context) — CRITICAL

**Problem:** Cron jobs fail with "mission file is missing" when the prompt tells the agent to load a mission file by a relative path (e.g., `skills/career_job-seeking/mission_job-registry-maintenance.md`). The file exists but the cron job's working directory doesn't resolve that path.

**Root cause:** Two file-access tools resolve paths differently — this is the key insight:

| Tool | Path resolution |
|------|----------------|
| `read_file("skills/career_job-seeking/mission_X.md")` | Resolves from **process CWD** (scheduler root: `~/.hermes/hermes-agent/`) → fails |
| `skill_view(name='career_job-seeking', file_path='mission_X.md')` | Resolves from the **skill's own directory on disk** (`~/.hermes/profiles/career-manager/skills/career_job-seeking/`) → works |

`read_file` has no knowledge of which skill is "loaded". `skill_view` knows exactly where each skill lives and resolves `file_path` relative to that skill directory.

**Fix options (preferred order):**

A. **(PREFERRED) Use `skill_view` in the cron prompt.** Write the prompt to explicitly load the mission file via `skill_view(name='<skill-name>', file_path='<mission-file>')`. This keeps the mission file as the **single source of truth** — the spec can be updated in one place and all crons pick up the change. Example:
   ```
   Load the job hunt mission spec using skill_view(name='career_job-seeking', file_path='mission_job-hunt.md') and follow it exactly: execute the full weekly job discovery pipeline...
   ```

B. **Embed mission content inline in the cron prompt.** Replace the `"per mission_X.md"` reference with the full spec content. No file path dependency, but duplicates content — if the mission spec changes, the cron prompt must be updated too. Acceptable for small specs (~4.5KB) but not ideal.

C. **Set `workdir` on the cron job.** Add `workdir="/home/mars/.hermes/profiles/career-manager"` to the cron job. When set, AGENTS.md from that directory is also injected. Note: jobs with `workdir` run sequentially (not parallel) to keep per-job directories isolated.

D. **Use absolute paths.** `read_file("/home/mars/.hermes/profiles/career-manager/skills/career_job-seeking/mission_X.md")`. Brittle — breaks if profile path changes.

**Pitfall — do not use `read_file` with relative paths from SKILL.md references:** The skill's SKILL.md content is injected as text into the prompt, not as a mounted filesystem. The agent can see the text `skills/career_job-seeking/mission_X.md` in the prompt but `read_file` will look for it under the scheduler's CWD, not under the skill directory. Always use `skill_view` instead.

**Detection:** If a cron job's `last_status` shows `ok` but the user reports receiving a "file missing" error, check whether the prompt references a relative file path. The job may have failed and the `[SILENT]` convention may suppress delivery of the failure.

**Latent risk:** Any cron job whose prompt says "per mission_X.md" or "read the mission file" without specifying HOW (using `skill_view` vs `read_file`) is exposed. Cron prompts should always use `skill_view` when they need to load a skill-linked file.

**Applied 2026-05-18 — fixed 3 crons with this pattern:**
- `d0c84c0cbb3e` (Job Registry Maintenance) — was using `read_file` with relative path → switched to `skill_view`
- `0c12bc1fd39e` (Weekly Job Hunt) — was using `read_file` with relative path → switched to `skill_view`
- `86f07be2b368` (Monthly Employment Optimizer) — was loading non-existent skill `career_employment-optimizer` → switched to `career_job-seeking` + `skill_view` on `references/employment-optimizer.md`

**Older crons not affected** (simple prompts, no mission file references):
- `e3d31e77d822` (Daily Pipeline) — uses absolute paths for data files
- `74b1faef5bc3` (Heartbeat) — simple prompt, no file loading needed
