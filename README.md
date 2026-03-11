# maximes-skills

A collection of skills for OpenClaw and compatible AI agents.

## Install

```bash
# Install all skills at once
npx skills add https://github.com/<your-username>/maximes-skills -g -a openclaw -y

# Or install a specific skill
npx skills add https://github.com/<your-username>/maximes-skills/tree/main/skills/stack-summary -g -a openclaw -y
```

## Available Skills

| Skill | Description |
|---|---|
| [stack-summary](./skills/stack-summary/) | Maintain living stack documentation: current architecture, archive changelog, and scheduled tasks registry |

## Repository Structure

```
maximes-skills/          ← single git repo
├── README.md
└── skills/
    └── stack-summary/
        ├── SKILL.md
        └── scripts/
            ├── gather_state.sh
            └── deploy.sh    ← local dev: syncs to ~/.agents/skills/stack-summary/
```

## Local Development

After editing a skill, sync it to OpenClaw with:
```bash
bash ~/aux_services/maximes-skills/skills/<skill-name>/scripts/deploy.sh
```
