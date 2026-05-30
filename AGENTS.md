# AGENTS.md — agent-skills (2026 Hermes era)

This repository contains a small set of actively maintained skills for the Hermes agent system running on the mars homelab host.

## Current Status

- Primary consumers: MARS (default), Andy (career-manager), Cooper (health-coach) on the shared `mars` host.
- Distribution: `hermes skills install` (or bulk import script from the hermes-agent skill).
- Old OpenClaw distribution (`npx skills add`, `~/.agents/skills/`, `deploy-openclaw.sh`) is **retired**.
- Only two skills are under active maintenance: `email-triage` and `latex`.

## Workspace Rules

- **Do not** load the entire repo as an agent workspace.
- Skills are installed into `~/.hermes/skills/` (or per-profile `~/.hermes/profiles/<name>/skills/`).
- The `draft/` directory contains historical material only.
- When editing, keep the focus on Hermes-native patterns (kanban dispatch, profile handoff, MCP where useful, `CORRESPONDANCE_ROOT` env convention, etc.).

## Multi-Agent Dispatch Pattern (email-triage)

The canonical "heartbeat" for the shared personal Gmail inbox lives in the `email-triage` skill + its companion gate script.

See `skills/email-triage/SKILL.md` for the full contract, mutation rules, and recommended cron registration on the default (MARS) profile.

## Document Production (latex)

All three agents produce formal documents using per-profile `CORRESPONDANCE_ROOT` paths.

The skill supports projects with **multiple entrypoints** that share common files (placed in `common/` by convention). See `skills/latex/SKILL.md` and the template `skills/latex/templates/correspondance-root-AGENTS.md`.

A `AGENTS.md` file should be placed at the root of each profile's correspondance directory to document local conventions.

## Code Review & Changes

- Prefer small, surgical changes to the two active skills.
- Any change to dispatch or mutation semantics in email-triage must be reflected in the heartbeat cron prompt and gate script.
- Update this file and the top-level README when the set of maintained skills changes.

## Historical Note

This repo began during the OpenClaw period. The 2026 revamp removed everything that was superseded by Hermes providers, the `delegation` toolset, kanban, profiles, and the curator system. Only the two skills with ongoing operational value on the mars host were kept and rewritten.
