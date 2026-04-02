# agent-skills

A collection of skills for AI coding agents (GitHub Copilot, Hermes, and compatible agents).

## Skills

| Skill | Description |
|---|---|
| [stack-summary](./skills/stack-summary/) | Maintain living architecture docs: current stack snapshot, archive changelog, and scheduled tasks registry |

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

# Deploy all skills to ~/.agents/skills/ for local testing
bash deploy-openclaw.sh

# Deploy a specific skill
bash deploy-openclaw.sh stack-summary
```

After local testing, push to GitHub and reinstall via `npx skills add` or `hermes skills install` above.

### Adding a skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`) and operation docs
2. Add scripts to `skills/<name>/scripts/` if needed
3. Run `bash deploy-openclaw.sh <name>` to install locally for testing
4. Push to GitHub: `git push origin main`
5. Reinstall from GitHub: `npx skills add ... -g -a github-copilot -y`
6. Add a row to the table above
