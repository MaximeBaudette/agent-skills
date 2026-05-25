---
name: stack-summary
description: "Maintain living stack documentation in the Prime Radiant KB. Use this skill whenever: updating STACK/CURRENT after infrastructure changes, creating archive entries for deprecated components, documenting a new service/skill/plugin being added or removed, syncing the cron/service registry, or when the user asks to 'update stack docs', 'document this change', 'archive this setup', 'sync cron docs', 'update CRONs', 'what's in the stack', or 'generate stack summary'. Also use this when you've just finished installing or removing any service, plugin, skill, tool, or cron and the user hasn't explicitly asked — proactively suggest documenting it."
---

# Stack Summary Skill

Maintains living architecture documentation in the **Prime Radiant KB** (not the filesystem). The KB is the source of truth.

```
KB pages:
  STACK/CURRENT                              ← current state snapshot (always up to date)
  STACK/CRONs                                ← scheduled tasks registry (crons, systemd services)
  STACK/Archive/YYYY-MM-DD_slug              ← one page per architectural change
  articles/mars-host                         ← hardware specs, networking, backup (rarely changes)
```

## Operations

Three operations, used in combination:

1. **`update-stack`** — regenerate `STACK/CURRENT` from live system state, commit to KB
2. **`sync-crons`** — rewrite `STACK/CRONs` from live cron/service state, commit to KB
3. **`archive-change`** — create a new `STACK/Archive/YYYY-MM-DD_slug` page in KB

> When removing or replacing something, run `archive-change` **before** `update-stack` — preserve the old state first, then update the current view.

### KB Tools Used
- `mcp_prime_radiant_kb_get_page` — read existing KB page
- `mcp_prime_radiant_kb_commit_page` — write final page (MARS only, re-indexes + git commits)
- `mcp_prime_radiant_kb_list_pages` — list pages in a source (e.g., `STACK`)
- `mcp_prime_radiant_kb_search` — search across KB

---

## Operation 1: update-stack

### When to use
- After installing or removing a service, plugin, skill, or tool
- When any port, path, or config changes
- When user asks "update stack docs" or "regenerate CURRENT"

### Steps

1. **Read the existing KB page** to understand current structure:
   ```
   kb_get_page(slug="STACK/CURRENT")
   ```

2. **Gather live system state** via terminal commands:
   ```bash
   # Runtime versions
   node --version && python3 --version && npm --version

   # Hermes version
   hermes --version 2>/dev/null || echo "not found"

   # Hermes profiles
   ls ~/.hermes/profiles/ 2>/dev/null

   # Active systemd user services
   systemctl --user list-units --type=service --state=active --no-pager

   # Listening ports
   ss -tlnp 2>/dev/null

   # Aux services
   ls ~/aux_services/ 2>/dev/null

   # Local binaries
   ls ~/bin/ 2>/dev/null

   # Skills directory listing (top-level categories)
   ls -d ~/.hermes/skills/*/ 2>/dev/null
   ```

3. **Update each section** in `STACK/CURRENT` from the gathered output:
   - **Runtime** — node, python3, npm versions
   - **Agent Framework** — Hermes version, profiles, any config notes
   - **Services** — active systemd user services
   - **Ports** — listening ports with process info
   - **Aux Services** — entries in `~/aux_services/`
   - **Binaries** — entries in `~/bin/`
   - **Skills Dirs** — top-level skill categories
   - **Recent Skill/Cron Changes** — update if anything changed since last update
   - **Profile sections** — update per-profile details if changed (model routing, skills, crons)

4. **Update the `Last updated:` date** at the top.

5. **Commit to KB:**
   ```
   kb_commit_page(slug="STACK/CURRENT", content="<full markdown>")
   ```

> **Don't** update `articles/mars-host` as part of this operation — that page covers hardware/network specs that rarely change. Update it separately if hardware changes.

---

## Operation 2: sync-crons

### When to use
- After adding or removing any cron job, systemd service, or scheduled task
- When the user asks "sync cron docs", "update CRONs", or "document this cron"
- After any `cronjob` tool operation (create, update, remove)

### Steps

1. **Read the existing KB page:**
   ```
   kb_get_page(slug="STACK/CRONs")
   ```

2. **Collect Hermes cron state** for all profiles:
   ```bash
   # Default profile (MARS)
   hermes cron list

   # Each additional profile
   for profile in ~/.hermes/profiles/*/; do
     name=$(basename "$profile")
     echo "=== Profile: $name ==="
     hermes -p "$name" cron list
   done
   ```

3. **Collect system-level state:**
   ```bash
   crontab -l 2>/dev/null
   systemctl --user list-units --type=service --state=active --no-pager
   ```

4. **Rewrite `STACK/CRONs`** with sections:
   - **Hermes Cron Jobs (MARS/default)** — ID, Name, Schedule, Skills, Notes
   - **Hermes Crons (career-manager/Andy)** — same columns
   - **Hermes Crons (health-coach/Cooper)** — same columns
   - **Systemd User Services (active)** — Service, Status
   - **System Crons (crontab -l)** — Schedule, Script, Notes
   - **Retired** — keep any previously documented retired entries

5. **Update the `Last updated:` date** at the top.

6. **Commit to KB:**
   ```
   kb_commit_page(slug="STACK/CRONs", content="<full markdown>")
   ```

---

## Operation 3: archive-change

### When to use
- Removing or replacing a service, tool, plugin, or skill
- Completing a significant infrastructure migration
- Changing a fundamental configuration (LLM provider, memory backend, etc.)
- User says "archive this change" or "document what we just replaced"

### Steps

1. **Determine an archive slug:** short, kebab-case, descriptive  
   Examples: `memory-byterover-to-always-on-agent`, `add-composio-plugin`, `upgrade-hermes-2026-05`

2. **Create the KB page** at `STACK/Archive/YYYY-MM-DD_slug` using this template:

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

3. **Skip sections that don't apply** (e.g., no "Removed" if this is a pure addition).

4. **Commit to KB:**
   ```
   kb_commit_page(slug="STACK/Archive/YYYY-MM-DD_slug", content="<full markdown>")
   ```

5. **Follow up with `update-stack`** to refresh `STACK/CURRENT`.

---

## Conventions

- **CURRENT** — present state only; no historical information
- **CRONs** — live registry, keep retired entries in a Retired section
- **Archive slugs** — `YYYY-MM-DD_kebab-case-description`
- **Change types:** `Infrastructure replacement`, `Addition`, `Removal`, `Configuration`, `Upgrade`, `Documentation`
- **No secrets** — reference where a secret is stored, never the value itself
- **KB commits are auto-versioned** — no need for manual git operations; `kb_commit_page` handles re-indexing and git commit
- **Tables in KB pages** — markdown tables are fine in the KB (unlike Telegram); use them for structured data

---

## Cross-References

- Hardware specs live in `articles/mars-host` — update separately when hardware changes
- Docs toolchain context in `ops/docs-toolchain`
- AGENTS.md at `~/.hermes/AGENTS.md` documents MARS's KB curator role
