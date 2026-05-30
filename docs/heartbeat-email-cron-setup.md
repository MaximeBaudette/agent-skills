# Re-creating the MARS Heartbeat Cron for Personal Email Triage (2026)

The original "heartbeat" (cron ID 563ef29a11d9) that polled the shared `maximes.butler@gmail.com` inbox, ran classification via email-triage, and dispatched to Andy/Cooper via the old agent-dispatch path no longer exists in the active scheduler.

This document gives the exact steps to bring a modern, clean equivalent back online using the revamped `email-triage` skill.

## 1. Install the skill (on mars, as the mars user)

```bash
export PATH="$HOME/.local/bin:$PATH"

python ~/.hermes/skills/autonomous-ai-agents/hermes-agent/scripts/bulk-import-skills.py \
  https://github.com/MaximeBaudette/agent-skills main
```

Or install just the one skill:

```bash
hermes skills install https://github.com/MaximeBaudette/agent-skills/tree/main/skills/email-triage
```

Verify:

```bash
hermes skills list | grep email-triage
```

Make sure it is enabled for the gateway / CLI on the default profile.

## 2. Gate script

The inbox polling cron continues to use the existing `cron_gate_inbox_poll.py` (kept under its original name). No new gate script is shipped with the email-triage skill.

## 3. Create the cron on the default (MARS) profile

```bash
hermes cron create '*/30 7-23 * * *' \
  --name "heartbeat: personal email triage" \
  --script gate_personal_email.py \
  --prompt 'Read the gate output above. If it is exactly "[SILENT]", respond with exactly "[SILENT]" and nothing else. Otherwise load the email-triage skill and process the messages according to its rules. Emit [SILENT] only when the entire run produced zero mutations and no escalations.' \
  --deliver local \
  --workdir /home/mars/.hermes/workspace
```

Adjust the schedule as you like (the old one was often every 30 min during waking hours).

## 4. Test manually first

```bash
python ~/.hermes/scripts/gate_personal_email.py
```

- Clean inbox → should print exactly `[SILENT]`
- Mail present → prints a compact JSON envelope

Then run a one-shot with the skill:

```bash
hermes chat -q "Run email-triage inbox sweep using the gate output if available. Follow all mutation rules strictly." --profile default
```

## 5. Per-profile correspondance roots (for latex, while you're here)

Add to each profile's `.env` (or document in their AGENTS.md):

```bash
# Andy
CORRESPONDANCE_ROOT=/home/mars/.hermes/profiles/career-manager/workspace/correspondance

# Cooper
CORRESPONDANCE_ROOT=/home/mars/.hermes/profiles/health-coach/workspace/correspondance

# MARS
CORRESPONDANCE_ROOT=/home/mars/.hermes/workspace/correspondance
```

Create the directories if they don't exist.

## 6. Monitoring

- The cron will appear in `hermes cron list` on the default profile.
- Failed auth will be caught by the gate + the skill's auth check.
- Look for `[SILENT]` in the cron output history to confirm quiet runs are cheap.
- Use the kanban board (already active) to watch handoffs to Andy and Cooper.

Once this cron is live again, the original design (MARS as the shared-inbox triage + lightweight handoff of just the message ID) is restored with modern Hermes primitives.
