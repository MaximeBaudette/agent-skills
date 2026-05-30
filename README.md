# agent-skills (2026 Hermes revamp)

Modern, minimal collection of skills for the Hermes multi-agent setup on the mars homelab host (MARS + Andy career-manager + Cooper health-coach).

Only skills that are actively maintained and relevant after the move from OpenClaw to Hermes are kept here.

## Currently Maintained

| Skill | Purpose | Notes |
|-------|---------|-------|
| [email-triage](./skills/email-triage/) | Classifies mail from the shared inbox by topic and dispatches to Andy / Cooper (or keeps with MARS). Self-contained. | Invoked by the inbox polling cron (historically called heartbeat). Focus is classification + safe dispatch. |
| [latex](./skills/latex/) | Formal document production. Supports projects with multiple entrypoints that share common files (preambles, constants, etc.). | Pure skill + improved scripts. Includes a ready-to-use multi-document example template. Per-profile `CORRESPONDANCE_ROOT`. |

## Obsolete / Archived (do not use)

The following were tied to OpenClaw paths, the old `npx skills add` distribution, or have been superseded by Hermes native features:

- `gemini-cli` — replaced by native `google-gemini-cli` provider + `delegation` tool + `autonomous-ai-agents/*` patterns.
- `agent-review` — hard-coded to `~/.openclaw/...` layout.
- `agent-dispatch` — logic absorbed into `email-triage`.
- `stack-summary` — superseded by KB entities + curator + encyclopedist flows.

These remain in the tree only for historical reference. They will be moved to `archive/` in a future cleanup.

## Installation (Hermes)

```bash
# One skill
hermes skills install https://github.com/MaximeBaudette/agent-skills/tree/main/skills/email-triage

# Or use the bulk importer (recommended for collections)
python ~/.hermes/skills/autonomous-ai-agents/hermes-agent/scripts/bulk-import-skills.py \
  https://github.com/MaximeBaudette/agent-skills main
```

After import, review with `hermes skills list` and enable on the relevant platforms/profiles.

## Development on mars

```bash
# Hot-reload only (not for production)
bash deploy.sh email-triage
```

The old `deploy-openclaw.sh` is dead.

## Design Principles (post-OpenClaw)

- Skills are self-contained where possible.
- Dispatch between profiles prefers Hermes-native mechanisms (kanban, `delegate_task`, direct `hermes chat -p`).
- Document production uses per-profile isolation + shared compiler (MCP when it makes sense).
- The "heartbeat" concept for the shared personal inbox is explicitly supported and documented.
- No hard-coded `~/.openclaw` or `~/.agents` paths remain in active skills.

## License

MIT
