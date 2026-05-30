---
name: stack-summary
description: "Maintain living stack documentation for the MARS host in the Prime Radiant KB. Use this skill whenever: updating the mars host page after infrastructure changes, appending archive entries for deprecated components, documenting a new service/skill/plugin being added or removed, or when the user asks to 'update stack docs', 'document this change', 'archive this setup', 'what's in the stack', or 'generate stack summary'. Also use when you've just finished installing or removing any service, plugin, skill, tool, or cron — proactively suggest documenting it."
---

# Stack Summary Skill

Maintains living architecture documentation for the MARS host in the **Prime Radiant KB**. Two pages, one living + one append-only:

```
entities/agents/mars.md              ← THE page — hardware, runtime, services, ports, crons, skills, profiles, config
entities/agents/mars-archive.md      ← append-only changelog (one page, entries added over time)
```

## Operations

Two operations:

1. **`update-stack`** — regenerate `entities/agents/mars.md` from live system state, commit to KB
2. **`archive-change`** — append a new dated entry to `entities/agents/mars-archive.md`

> When removing or replacing something, run `archive-change` **before** `update-stack` — preserve the old state first, then update the current view.

### KB Tools Used
- `mcp_prime_radiant_kb_get_page` — read existing KB page
- `mcp_prime_radiant_kb_commit_page` — write final page (MARS only, re-indexes + git commits)
- `mcp_prime_radiant_kb_search` — search across KB

---

## Operation 1: update-stack

### When to use
- After installing or removing a service, plugin, skill, tool, or cron
- When any port, path, or config changes
- When user asks "update stack docs" or "regenerate the mars page"

### Steps

1. **Read the existing KB page** to understand current structure:
   ```
   kb_get_page(slug="entities/agents/mars")
   ```

2. **Gather live system state** via terminal commands:
   ```bash
   # Hardware
   hostnamectl && free -h && df -h /

   # Runtime versions
   node --version && python3 --version && npm --version

   # Hermes version
   hermes --version 2>/dev/null

   # Hermes profiles
   ls ~/.hermes/profiles/ 2>/dev/null

   # Active systemd user services
   systemctl --user list-units --type=service --state=active --no-pager

   # Listening ports
   ss -tlnp 2>/dev/null

   # Hermes cron jobs (all profiles)
   hermes cron list
   for profile in ~/.hermes/profiles/*/; do
     name=$(basename "$profile")
     echo "=== $name ==="
     hermes -p "$name" cron list
   done

   # System crons
   crontab -l 2>/dev/null

   # Aux services
   ls ~/aux_services/ 2>/dev/null

   # Local binaries
   ls ~/bin/ 2>/dev/null

   # Skills directory listing
   ls -d ~/.hermes/skills/*/ 2>/dev/null
   ```

3. **Rewrite `entities/agents/mars.md`** with all sections in one page:

```markdown
---
title: MARS Host
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: entity
tags: [mars, host, infrastructure, stack, cron, hermes]
---

# MARS Host

> Living architecture page for the MARS agent host. Last updated: YYYY-MM-DD

## Hardware
- **Hostname:** mars
- **OS:** Ubuntu 24.04 LTS
- **CPU:** 8-core Intel i7
- **RAM:** 32 GB
- **Storage:** 500 GB NVMe + 4 TB external HDD (borgbackup)
- **Network:** 192.168.0.6, static DHCP, VLAN-isolated lab subnet

## Runtime
- Node: vXX.XX.X
- Python3: X.XX.X
- NPM: XX.X.X

## Agent Framework
- Hermes: vX.X.X
- Profiles: default (MARS), career-manager (Andy), health-coach (Cooper)
- [Any current config notes]

## Services (systemctl --user active)
| Service | Notes |
|---------|-------|
| name.service | brief purpose |

## Ports
| Port | Process | Notes |
|------|---------|-------|
| 0.0.0.0:8080 | hermes | gateway |

## Cron Jobs

### MARS (default)
| ID | Name | Schedule | Skills | Notes |
|---|------|----------|--------|-------|
| ... | ... | ... | ... | ... |

### Andy (career-manager)
| ID | Name | Schedule | Skills | Notes |
|---|------|----------|--------|-------|
| ... | ... | ... | ... | ... |

### Cooper (health-coach)
| ID | Name | Schedule | Skills | Notes |
|---|------|----------|--------|-------|
| ... | ... | ... | ... | ... |

### System Crons (crontab)
| Schedule | Script | Notes |
|----------|--------|-------|
| ... | ... | ... |

## Aux Services (~/aux_services)
| Service | Purpose |
|---------|---------|
| name | description |

## Binaries (~/bin)
| Binary | Purpose |
|--------|---------|
| name | description |

## Skills
[Top-level categories from ~/.hermes/skills/]

## Profiles
[Per-profile details: model routing, workspace paths, notable config]

## Backup
- borgbackup: daily /home/mars → 4 TB HDD, 30-day retention, LZ4 compression
```

4. **Update the `updated` date** in frontmatter and the "Last updated" line.

5. **Commit to KB:**
   ```
   kb_commit_page(slug="entities/agents/mars", content="<full markdown>")
   ```

---

## Operation 2: archive-change

### When to use
- Removing or replacing a service, tool, plugin, or skill
- Completing a significant infrastructure migration
- Changing a fundamental configuration (LLM provider, memory backend, etc.)
- User says "archive this change" or "document what we just replaced"

### Steps

1. **Determine an archive slug:** short, kebab-case, descriptive  
   Examples: `memory-byterover-to-always-on-agent`, `add-composio-plugin`, `upgrade-hermes-2026-05`

2. **Read the current archive page:**
   ```
   kb_get_page(slug="entities/agents/mars-archive")
   ```

3. **Prepend a new entry** at the top (after the frontmatter/header) using this template:

```markdown
## YYYY-MM-DD — [Human-readable title]

**Change type:** [Infrastructure replacement | Addition | Removal | Configuration | Upgrade | Documentation]
**Summary:** One sentence describing what changed and why.

### What Changed

#### Removed (if applicable)
| Component | What it was | Why removed |
|---|---|---|
| Name | Brief description | Reason |

#### Added (if applicable)
| Component | Location | What it does |
|---|---|---|
| Name | Path | Description |

#### Modified (if applicable)
| Component | What changed |
|---|---|
| Name | Description of change |

### Why
[2-4 sentences explaining the motivation.]

### Before → After (if applicable)
**Before:** [brief description]
**After:** [brief description]

### Remnants (if applicable)
| Path | Status | Notes |
|---|---|---|
| path | Keep/Delete | Why |

---
```

4. **Skip sub-sections that don't apply** (e.g., no "Removed" if pure addition).

5. **Commit to KB:**
   ```
   kb_commit_page(slug="entities/agents/mars-archive", content="<full markdown with new entry prepended>")
   ```

6. **Follow up with `update-stack`** to refresh `entities/agents/mars.md`.

---

## Conventions

- **mars.md** — present state only; no historical information. Everything about the host in one page.
- **mars-archive.md** — append-only (prepend new entries at top). One page forever, grows over time.
- **Archive entries** — `## YYYY-MM-DD — Title` as H2 sections, separated by `---`
- **Change types:** `Infrastructure replacement`, `Addition`, `Removal`, `Configuration`, `Upgrade`, `Documentation`
- **No secrets** — reference where a secret is stored, never the value itself
- **KB commits are auto-versioned** — `kb_commit_page` handles re-indexing and git commit
- **Tables are fine** in KB pages (unlike Telegram)

---

## Legacy Pages (deprecated)

These KB pages were superseded by `entities/agents/mars.md` + `entities/agents/mars-archive.md`:

- ~~`STACK/CURRENT`~~ → merged into `entities/agents/mars.md`
- ~~`STACK/CRONs`~~ → merged into `entities/agents/mars.md`
- ~~`STACK/Archive/*`~~ → consolidated into `entities/agents/mars-archive.md`
- ~~`articles/mars-host`~~ → merged into `entities/agents/mars.md`

If these old pages still exist, they should be removed or replaced with redirect notes pointing to the new pages.
