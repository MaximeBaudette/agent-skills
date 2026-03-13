# Copilot Instructions — maximes-skills

## What this repo is

A monorepo of **OpenClaw skills** — instruction bundles that teach an AI agent how to perform specific operations. Each skill is a directory under `skills/` containing a `SKILL.md` and optional `scripts/`.

OpenClaw loads skills from `~/.agents/skills/`. This repo is the **source of truth**; skills are deployed to that path via rsync.

## Deploy commands

```bash
# Deploy all skills to ~/.agents/skills/
bash deploy-openclaw.sh

# Deploy one skill
bash deploy-openclaw.sh stack-summary

# From inside a skill (convenience wrapper):
bash skills/stack-summary/scripts/deploy.sh
```

No restart required — OpenClaw picks up changes on the next skill load. There are no build, test, or lint steps.

## Architecture

### Skill structure

Each skill directory must contain a `SKILL.md` at its root (the deploy script skips directories without one). The `SKILL.md` serves dual purpose: it's both the human docs and the instruction file OpenClaw reads.

```
skills/<name>/
├── SKILL.md          ← required; OpenClaw reads this as the skill definition
└── scripts/          ← optional bash scripts the skill instructs the agent to run
    └── *.sh
```

### SKILL.md format

The file must start with YAML frontmatter:

```yaml
---
name: skill-name
description: "Activation text — this is what OpenClaw uses to decide when to invoke the skill. Make it comprehensive: include explicit trigger phrases (e.g., 'update stack docs', 'sync cron docs') and implicit scenarios."
---
```

The body documents named **operations** (e.g., `update-stack`, `archive-change`, `sync-crons`). Each operation includes:
- When to use it
- Step-by-step instructions (including exact shell commands)
- Commit message conventions

### Key conventions

- **`description` frontmatter is critical** — it's how OpenClaw matches user intent to the skill. It should include explicit trigger phrases in quotes and implicit scenarios.
- **Operations reference scripts by absolute path** (e.g., `bash ~/aux_services/stack-summary/scripts/gather_state.sh`), not relative paths, because the agent runs them from arbitrary working directories.
- **Scripts use `set -euo pipefail`** and accept configuration via environment variables with `${VAR:-default}` fallbacks.
- **No secrets in docs** — reference the storage location (e.g., "API key in `.env`"), never the value.
- **Commit message conventions are part of the skill spec** — document them explicitly so the agent uses consistent formats.

### Adding a new skill

1. Create `skills/<name>/SKILL.md` with frontmatter + operation docs
2. Add scripts to `skills/<name>/scripts/` if needed
3. Run `bash deploy-openclaw.sh <name>` to install
4. Add a row to the README table

### gather_state.sh note

`skills/stack-summary/scripts/gather_state.sh` reads `~/.openclaw/workspace/CRONs.md` for cron data. The canonical cron registry has moved to `~/STACK/CRONs.md` — if you update this script, change that reference.
