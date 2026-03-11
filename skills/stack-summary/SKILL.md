---
name: stack-summary
description: "Maintain living stack documentation for an OpenClaw-powered AI agent host. Use this skill whenever: updating STACK/CURRENT.md after infrastructure changes, creating archive entries for deprecated components, documenting a new service/skill/plugin being added or removed, syncing the cron/service registry, or when the user asks to 'update stack docs', 'document this change', 'archive this setup', 'sync cron docs', 'update CRONs.md', 'what's in the stack', or 'generate stack summary'. Also use this when you've just finished installing or removing any service, plugin, skill, tool, or cron and the user hasn't explicitly asked — proactively suggest documenting it."
---

# Stack Summary Skill

Maintains a living architecture documentation directory at `~/STACK/` (configurable — see [Configuration](#configuration)):

```
~/STACK/
├── CURRENT.md              ← current state snapshot (always up to date)
├── CRONs.md                ← scheduled tasks registry (crons, systemd services)
└── Archive/
    └── YYYY-MM-DD_<slug>.md   ← one file per architectural change
```

## Configuration

This skill uses two environment variables (with sensible defaults):

| Variable | Default | Description |
|---|---|---|
| `STACK_DIR` | `~/STACK` | Where to store `CURRENT.md`, `CRONs.md`, and `Archive/` |
| `STACK_SKILL_DIR` | `~/aux_services/stack-summary` | Where this skill is installed |

## Deploying / Updating the Skill

OpenClaw loads skills from `~/.agents/skills/`. After editing `SKILL.md` or `scripts/`, sync to the install location:

```bash
bash ~/aux_services/stack-summary/scripts/deploy.sh
```

This uses `rsync` to copy the repo to `~/.agents/skills/stack-summary/` (excluding `.git`).

> **Note for publishers:** The repo at `~/aux_services/stack-summary/` is the source of truth for development. Clone it and run `deploy.sh` (adjusted for your path) to install.

Set these in your shell profile if your paths differ from the defaults. The examples in this skill use `~/STACK` and `~/aux_services/stack-summary` for clarity.

The skill has two operations:
1. **`update-stack`** — regenerate `STACK/CURRENT.md` from current system state
2. **`archive-change`** — create a new `STACK/Archive/YYYY-MM-DD_<slug>.md` entry

Use `archive-change` BEFORE `update-stack` when removing or replacing something — preserve what it was, then update the current view.

---

## Operation 1: update-stack

### When to use
- After installing or removing a service, plugin, skill, or tool
- When any port, path, or config changes
- Periodically (e.g., after a session where infrastructure was modified)
- When user asks "update stack docs" or "regenerate CURRENT.md"

### Steps

1. Run the gather script to collect current system state:
   ```bash
   bash ~/aux_services/stack-summary/scripts/gather_state.sh
   ```

2. Read the current `~/STACK/CURRENT.md` to understand the existing structure.

3. Update each section in `CURRENT.md` from the script output:
   - **Runtime Stack** — node, python3, npm versions from `--- RUNTIME ---`
   - **OpenClaw** section — version, plugins, agents, providers from `--- OPENCLAW ---`
   - **Memory Architecture** — verify services and endpoints are current
   - **Plugins table** — update enabled/disabled from `plugins_enabled` / `plugins_disabled`
   - **Skills** — update from `--- SKILLS ---`
   - **Auxiliary Services** — update from `--- AUX_SERVICES ---`
   - **Ports & Networking** — update from `--- PORTS ---`
   - **Scheduled Tasks** — update from `--- CRONS ---`

4. Update the `Last updated:` date at the top.

5. Commit the change:
   ```bash
   cd ~/STACK && git add CURRENT.md && git commit -m "docs: update stack snapshot YYYY-MM-DD"
   ```

---

## Operation 3: sync-crons

### When to use
- After adding or removing any cron job, systemd service, or scheduled task
- When the user asks "sync cron docs", "update CRONs.md", or "document this cron"
- Periodically to ensure `STACK/CRONs.md` reflects reality
- After any OpenClaw cron change (`openclaw cron add/delete`)

### Steps

1. Collect live cron state:
   ```bash
   # OpenClaw cron jobs
   openclaw cron list

   # System crontab
   crontab -l

   # Active systemd user services
   systemctl --user list-units --type=service --state=active --no-pager
   ```

2. Read current `~/STACK/CRONs.md` to see what's already documented.

3. Rewrite `~/STACK/CRONs.md` with three sections:
   - **OpenClaw Cron Jobs** — from `openclaw cron list` output (ID, Name, Schedule, Status, Notes)
   - **System Cron Jobs** — from `crontab -l` output (Name, Schedule, Command, Status, Notes)
   - **Systemd User Services** — from `systemctl --user` output (Service, Status, Port, Notes)

4. Update the `Last updated:` date at the top.

5. Commit:
   ```bash
   cd ~/STACK && git add CRONs.md && git commit -m "crons: sync scheduled tasks registry YYYY-MM-DD"
   ```

> **Note:** `~/STACK/CRONs.md` is the source of truth. The workspace `~/.openclaw/workspace/CRONs.md` (if it exists) is a stub that redirects here — do not maintain it separately.

---

## Operation 2: archive-change

### When to use
- Removing or replacing a service, tool, plugin, or skill
- Completing a significant infrastructure migration
- Changing a fundamental configuration (LLM provider, memory backend, etc.)
- User says "archive this change" or "document what we just replaced"

### Steps

1. Determine an archive slug: short, kebab-case, descriptive  
   Examples: `memory-byterover-to-always-on-agent`, `add-composio-plugin`, `remove-pinchtab`, `upgrade-openclaw-2026-04`

2. Create the archive file at `~/STACK/Archive/YYYY-MM-DD_<slug>.md` using this template:

```markdown
# YYYY-MM-DD — [Human-readable title]

**Change type:** [Infrastructure replacement | Addition | Removal | Configuration | Upgrade | Documentation]
**Date:** YYYY-MM-DD
**Summary:** One sentence describing what changed and why.

---

## What Changed

### Removed (if applicable)

| Component | What it was | Why removed |
|---|---|---|
| Name | Brief description | Reason |

### Added (if applicable)

| Component | Location | What it does |
|---|---|---|
| Name | Path | Description |

### Modified (if applicable)

| Component | What changed |
|---|---|
| Name | Description of change |

---

## Why This Change

[2-4 sentences explaining the motivation, what problem it solved, or what drove the decision.]

## Architecture Before → After (if applicable)

**Before:**
[brief description or ascii diagram]

**After:**
[brief description or ascii diagram]

---

## Remnants / Leftovers (if applicable)

| Path | Status | Notes |
|---|---|---|
| path | Keep/Delete | Why |
```

3. Fill in all applicable sections. Skip sections that don't apply (e.g., no "Removed" section if this is a pure addition).

4. Commit the archive file:
   ```bash
   cd ~/STACK && git add Archive/ && git commit -m "archive: YYYY-MM-DD <slug>"
   ```

5. Optionally follow up with `update-stack` to update CURRENT.md to reflect the change.

---

## File Conventions

- **CURRENT.md** — always reflects present state; never contains historical information
- **Archive slugs** — `YYYY-MM-DD_kebab-case-description.md` — no spaces, no uppercase, no special chars except hyphens and underscores
- **Change types:** `Infrastructure replacement`, `Addition`, `Removal`, `Configuration`, `Upgrade`, `Documentation`
- **Commit messages:** `docs: update stack snapshot YYYY-MM-DD` for CURRENT.md; `archive: YYYY-MM-DD <slug>` for archive entries
- **No secrets** — reference secret storage location (e.g., "API key in `.env`"), never put actual key values in docs

---

## Script Reference

`scripts/gather_state.sh` — collects system state from:
- OpenClaw version (`openclaw --version`)
- Config parsing (`~/.openclaw/openclaw.json`) — agents, plugins, providers, memory backend
- Active systemd user services
- Listening ports (`ss -tlnp`)
- Installed skills (`~/.openclaw/skills/`)
- Extensions (`~/.openclaw/extensions/`)
- Auxiliary services (`~/aux_services/`)
- Local binaries (`~/bin/`)
- Cron registry (`~/.openclaw/workspace/CRONs.md`)

Run it manually with:
```bash
bash ~/aux_services/stack-summary/scripts/gather_state.sh
```

> **Tip:** If your OpenClaw or STACK directory is not at the default location, update the path variables at the top of `gather_state.sh` before running.
