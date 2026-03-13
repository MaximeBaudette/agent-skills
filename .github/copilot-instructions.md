# Copilot Instructions — maximes-skills

## What this repo is

A GitHub-published collection of **OpenClaw skills** — instruction bundles that teach an AI agent how to perform specific operations. Each skill lives under `skills/<name>/` and contains a `SKILL.md` plus optional `scripts/`.

Skills are distributed via GitHub and installed with `npx skills add`. This repo is the **authoring source**; it is not loaded directly by OpenClaw.

## Installing skills

```bash
# Install all skills from this repo
npx skills add https://github.com/MaximeBaudette/agent-skills -g -a openclaw -y

# Install a specific skill
npx skills add https://github.com/MaximeBaudette/agent-skills/tree/main/skills/stack-summary -g -a openclaw -y
```

`npx skills add` installs skills into `~/.agents/skills/`. OpenClaw picks them up on the next skill load — no restart needed.

## Local development

`deploy-openclaw.sh` is a **dev-only shortcut** for testing skills locally without a GitHub push. Use it while iterating on a skill in progress:

```bash
# Sync all skills to ~/.agents/skills/ for local testing
bash deploy-openclaw.sh

# Sync a specific skill
bash deploy-openclaw.sh stack-summary
```

Once a skill is ready, push to GitHub and install via `npx skills add` as above.

There are no build, test, or lint steps.

## Architecture

### Skill structure

Each skill directory must contain a `SKILL.md` at its root (the deploy script and `npx skills add` both skip directories without one). The `SKILL.md` serves dual purpose: it's both the human docs and the instruction file OpenClaw reads.

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
- **Scripts must be self-contained** — they are installed to `~/.agents/skills/<name>/scripts/` and must not hardcode paths back to this source repo. Reference only paths in the user's environment (e.g., `~/STACK/`, `~/.openclaw/`).
- **Scripts use `set -euo pipefail`** and accept configuration via environment variables with `${VAR:-default}` fallbacks.
- **No secrets in docs** — reference the storage location (e.g., "API key in `.env`"), never the value.
- **Commit message conventions are part of the skill spec** — document them explicitly so the agent uses consistent formats.

### Adding a new skill

1. Create `skills/<name>/SKILL.md` with frontmatter + operation docs
2. Add scripts to `skills/<name>/scripts/` if needed (keep them self-contained — no source repo paths)
3. Test locally with `bash deploy-openclaw.sh <name>`
4. Push to GitHub
5. Install via `npx skills add <github-url>`
6. Add a row to the README table
