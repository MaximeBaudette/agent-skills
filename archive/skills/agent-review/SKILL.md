---
name: agent-review
description: "Weekly or on-demand audit of all agent workspaces (Cooper, Andy, MARS). Checks for stale script references, wrong skill paths, snapshot count drift, config vs file drift, and contradictory instructions. Auto-fixes simple unambiguous issues. Emails Maxime only for items requiring judgment. Silent on clean runs. MARS-only — do not invoke as Cooper or Andy."
homepage: https://github.com/MaximeBaudette/agent-skills
---

# Skill: agent-review

Invoked on-demand or weekly (Mondays). **MARS only** — do not run this as Cooper or Andy.

Reviews all three agent workspaces (Cooper, Andy, MARS) for internal discrepancies, stale references, and incoherence. Auto-fixes simple issues. Emails Maxime only if there are items that require his judgment.

---

## Step 1 — Read all key files for each agent

For each workspace, read the files listed below. **Read in parallel where possible.**

### Cooper (`~/.openclaw/agent_health/`)
- `AGENTS.md`, `SOUL.md`, `TOOLS.md`, `HEARTBEAT.md`, `MEMORY.md`
- `scripts/submit_task.py`, `scripts/batch_poll.py`, `scripts/scan_memory.py`, `scripts/update_watermark.py`, `scripts/check_symptom_followup.py`
- `skills/lab_results/SKILL.md`, `skills/symptom-tracker/SKILL.md`

### Andy (`~/.openclaw/career-manager/`)
- `AGENTS.md`, `SOUL.md`, `TOOLS.md`, `MEMORY.md`, `WEEKLY_HUNT.md`, `SKILLS.md`
- `career/profile/PROFILE.md`

### MARS (`~/.openclaw/workspace/`)
- `AGENTS.md`, `SOUL.md`, `IDENTITY.md`, `USER.md`, `TOOLS.md`, `MEMORY.md`, `HEARTBEAT.md`
- `~/.openclaw/openclaw.json` (agents section only — for config vs. file drift)

---

## Step 2 — Check for discrepancies

For each workspace, look for:

1. **Stale script names** — does any doc reference a script that no longer exists in `scripts/`?
2. **Wrong skill paths** — do AGENTS.md / TOOLS.md reference skill files that don't exist?
3. **Retired skills still referenced as active** — e.g. deprecated skills still in the main skill list
4. **Snapshot count drift** — does AGENTS.md / MEMORY.md say the right number of snapshot files?
5. **Config vs. file drift** — does `openclaw.json` reference files that are missing, or files exist that aren't registered?
6. **Contradictory instructions** — same instruction in two files says opposite things
7. **Stale date references** — files referencing years or dates that are clearly wrong for the context
8. **Missing cross-references** — HEARTBEAT.md references a skill that has no SKILL.md
9. **Broken cron/heartbeat registration** — a cron job references a script that doesn't exist

---

## Step 3 — Auto-fix what is simple and unambiguous

Fix directly (no confirmation needed) if ALL of these are true:
- The correct value is obvious (e.g., wrong filename in a path that clearly maps to one existing file)
- The fix is a string replacement or small addition — not a logic or policy change
- The fix affects only one workspace's documentation (not agent behavior)

**Examples of safe auto-fixes:**
- `batch_submit.py` → `submit_task.py` in a doc (script was renamed)
- `health-snapshot/SKILL.md` → `lab_results/SKILL.md` in a skill list
- `3 snapshot files` → `5 snapshot files` where the actual count is clearly 5
- A typo in a file path that clearly maps to one real path

**Never auto-fix:**
- Agent behavior rules (SOUL.md, core AGENTS.md rules)
- Anything that changes what an agent will DO, not just how a path is named
- Items where two interpretations are plausible

For each auto-fix applied, record: `[file] line X: changed "old" → "new"`

---

## Step 4 — Compile items requiring judgment

Collect all discrepancies that were NOT auto-fixed. For each:
- File path and line (or section)
- What the problem is
- What the options are (if not obvious)

---

## Step 5 — Output

### If there are judgment-required items:
Send an email to `maximes.baudette@gmail.com`:

**Subject:** `[Agent Review] X items need your attention — YYYY-MM-DD`

**Body:**
```
Hi Maxime,

Weekly agent review complete.

Auto-fixed:
- [list of auto-fixes, or "none"]

Items needing your decision:
1. [Cooper / Andy / MARS] — [file] — [description]
   Options: [a] ... [b] ...

2. ...

Let me know how you'd like to handle each.

— MARS
```

### If everything is clean (no judgment items):
Do nothing. No email, no Telegram message. Silent success.

### If auto-fixes were made but no judgment items:
No email needed. Optionally log to `~/.openclaw/workspace/memory/YYYY-MM-DD.md`:
```
## [HH:MM PT] Agent review — auto-fixed X items, all clean
[list of fixes]
```

---

## What this skill does NOT do
- Does not modify agent behavior (SOUL, core identity, behavior rules)
- Does not touch session files, credentials, or gateway config
- Does not check Andy's application pipeline or career data (out of scope)
- Does not run Cooper's heartbeat or submit any health batches
