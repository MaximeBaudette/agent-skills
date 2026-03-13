# agent-skills

A collection of skills for [OpenClaw](https://openclaw.dev) and compatible AI agents.

## Skills

| Skill | Description |
|---|---|
| [stack-summary](./skills/stack-summary/) | Maintain living architecture docs: current stack snapshot, archive changelog, and scheduled tasks registry |

## Installing a skill

```bash
# Install all skills
npx skills add https://github.com/MaximeBaudette/agent-skills -g -a openclaw -y

# Install a specific skill
npx skills add https://github.com/MaximeBaudette/agent-skills/tree/main/skills/stack-summary -g -a openclaw -y
```

## Local development

```bash
git clone git@github.com:MaximeBaudette/agent-skills.git
cd agent-skills

# Deploy all skills to ~/.agents/skills/
bash deploy-openclaw.sh

# Deploy a specific skill
bash deploy-openclaw.sh stack-summary
```

OpenClaw picks up changes on the next skill load — no restart needed.

### Adding a skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`) and operation docs
2. Add scripts to `skills/<name>/scripts/` if needed
3. Run `bash deploy-openclaw.sh <name>` to install locally
4. Add a row to the table above

