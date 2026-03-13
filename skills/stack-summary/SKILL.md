---
name: stack-summary
description: "Maintain living stack documentation for an OpenClaw-powered AI agent host. Use this skill whenever: updating STACK/CURRENT.md after infrastructure changes, creating archive entries for deprecated components, documenting a new service/skill/plugin being added or removed, syncing the cron/service registry, or when the user asks to 'update stack docs', 'document this change', 'archive this setup', 'sync cron docs', 'update CRONs.md', 'what's in the stack', or 'generate stack summary'. Also use this when you've just finished installing or removing any service, plugin, skill, tool, or cron and the user hasn't explicitly asked — proactively suggest documenting it."
---

# Stack Summary Skill

Maintains a living architecture documentation directory at `~/STACK/` (configurable via `STACK_DIR`):

```
~/STACK/
├── CURRENT.md              ← current state snapshot (always up to date)
├── CRONs.md                ← scheduled tasks registry (crons, systemd services)
└── Archive/
    └── YYYY-MM-DD_<slug>.md   ← one file per architectural change
```

## Configuration

Set `STACK_DIR` in your shell profile to change where the documentation lives (default: `~/STACK`).

## Operations

Three operations, used in combination:

1. **`update-stack`** — regenerate `STACK/CURRENT.md` from current system state
2. **`sync-crons`** — rewrite `STACK/CRONs.md` from live cron/service state
3. **`archive-change`** — create a new dated entry in `STACK/Archive/`

> When removing or replacing something, run `archive-change` **before** `update-stack` — preserve the old state first, then update the current view.

---

## Operation 1: update-stack

### When to use
- After installing or removing a service, plugin, skill, or tool
- When any port, path, or config changes
- When user asks "update stack docs" or "regenerate CURRENT.md"

### Steps

1. Run the gather script to collect current system state:
   ```bash
   bash ~/.agents/skills/stack-summary/scripts/gather_state.sh
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

5. Commit:
   ```bash
   cd ~/STACK && git add CURRENT.md && git commit -m "docs: update stack snapshot YYYY-MM-DD"
   ```

---

## Operation 2: sync-crons

### When to use
- After adding or removing any cron job, systemd service, or scheduled task
- When the user asks "sync cron docs", "update CRONs.md", or "document this cron"
- After any OpenClaw cron change (`openclaw cron add/delete`)

### Steps

1. Collect live cron state:
   ```bash
   openclaw cron list
   crontab -l
   systemctl --user list-units --type=service --state=active --no-pager
   ```

2. Read current `~/STACK/CRONs.md` to see what's already documented.

3. Rewrite `~/STACK/CRONs.md` with three sections:
   - **OpenClaw Cron Jobs** — from `openclaw cron list` (ID, Name, Schedule, Status, Notes)
   - **System Cron Jobs** — from `crontab -l` (Name, Schedule, Command, Notes)
   - **Systemd User Services** — from `systemctl --user` (Service, Status, Port, Notes)

4. Update the `Last updated:` date at the top.

5. Commit:
   ```bash
   cd ~/STACK && git add CRONs.md && git commit -m "crons: sync scheduled tasks registry YYYY-MM-DD"
   ```

---

## Operation 3: archive-change

### When to use
- Removing or replacing a service, tool, plugin, or skill
- Completing a significant infrastructure migration
- Changing a fundamental configuration (LLM provider, memory backend, etc.)
- User says "archive this change" or "document what we just replaced"

### Steps

1. Determine an archive slug: short, kebab-case, descriptive  
   Examples: `memory-byterover-to-always-on-agent`, `add-composio-plugin`, `upgrade-openclaw-2026-04`

2. Create `~/STACK/Archive/YYYY-MM-DD_<slug>.md` using this template:

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

3. Skip sections that don't apply (e.g., no "Removed" if this is a pure addition).

4. Commit:
   ```bash
   cd ~/STACK && git add Archive/ && git commit -m "archive: YYYY-MM-DD <slug>"
   ```

5. Follow up with `update-stack` to update CURRENT.md.

---

## File Conventions

- **CURRENT.md** — present state only; no historical information
- **Archive slugs** — `YYYY-MM-DD_kebab-case-description.md`
- **Change types:** `Infrastructure replacement`, `Addition`, `Removal`, `Configuration`, `Upgrade`, `Documentation`
- **Commit messages:** `docs: update stack snapshot YYYY-MM-DD` / `archive: YYYY-MM-DD <slug>` / `crons: sync scheduled tasks registry YYYY-MM-DD`
- **No secrets** — reference where a secret is stored, never the value itself

---

## Wiring into Agent Files

After installing this skill, add references to it in your agent's instruction files so it gets invoked automatically.

**In `TOOLS.md` (or equivalent):**
```markdown
## Stack Documentation (stack-summary skill)
- **Skill:** `stack-summary` (loaded from `~/.agents/skills/stack-summary/`)
- **Stack dir:** `~/STACK/CURRENT.md` — current architecture snapshot
- **Cron registry:** `~/STACK/CRONs.md` — canonical scheduled tasks registry
- **Archive:** `~/STACK/Archive/<YYYY-MM-DD>_<slug>.md` — one file per change
- **update-stack** → regenerate CURRENT.md (trigger: "update stack docs", "refresh the stack")
- **sync-crons** → rewrite CRONs.md (trigger: "sync cron docs", "document this cron")
- **archive-change** → new Archive/ entry (trigger: "archive this change")
- Always run sync-crons after adding or removing any cron, service, or scheduled task
```

**In `MEMORY.md` hard rules:**
```markdown
- **Stack docs:** update `~/STACK/CRONs.md` whenever adding/removing any cron/systemd job
```

---

## Script Reference

`scripts/gather_state.sh` collects system state from:
- OpenClaw version and config (`~/.openclaw/openclaw.json`) — agents, plugins, providers
- Active systemd user services
- Listening ports (`ss -tlnp`)
- Installed skills and extensions
- Auxiliary services (`~/aux_services/`)
- Local binaries (`~/bin/`)

Override paths via environment variables at the top of the script (`OPENCLAW_DIR`, `AUX_DIR`, `BIN_DIR`).

