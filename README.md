# agent-skills

A collection of skills for AI coding agents (GitHub Copilot, Hermes, and compatible agents).

## Skills

| Skill | Description |
|---|---|
| [stack-summary](./skills/stack-summary/) | Maintain living architecture docs: current stack snapshot, archive changelog, and scheduled tasks registry |
| [delegate](./skills/delegate/) | General-purpose inter-agent delegation for Andy/Cooper |
| [email-triage](./skills/email-triage/) | Gmail inbox sweep and targeted triage for MARS |

## Installing a skill

### For GitHub Copilot CLI (`-a github-copilot` → `~/.agents/skills/`)

```bash
# Install all skills
npx skills add https://github.com/MaximeBaudette/agent-skills -g -a github-copilot -y

# Install a specific skill
npx skills add https://github.com/MaximeBaudette/agent-skills/tree/main/skills/stack-summary -g -a github-copilot -y
```

### For Hermes Agent (`hermes skills` → `~/.hermes/skills/`)

```bash
hermes skills install https://github.com/MaximeBaudette/agent-skills/tree/main/skills/stack-summary
```

## Local development

```bash
git clone git@github.com:MaximeBaudette/agent-skills.git
cd agent-skills

# ONLY for hot-reload during active development — not a production deploy step
bash deploy-openclaw.sh          # all skills
bash deploy-openclaw.sh stack-summary  # specific skill
```

> **Note:** `npx skills add` already mirrors directly to `~/.agents/skills/`, so the deploy script is only needed when actively debugging and you need hot-reload without a GitHub push. Once tested: push to GitHub and update via `npx skills add`.

### Adding a skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`) and operation docs
2. Add scripts to `skills/<name>/scripts/` if needed
3. Test locally with `bash deploy-openclaw.sh <name>` (hot-reload only)
4. Push to GitHub: `git push origin main`
5. Install/update: `npx skills add ... -g -a github-copilot -y`
6. Add a row to the table above
