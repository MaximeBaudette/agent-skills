---
name: email-triage
description: "Classifies incoming emails from the shared maximes.butler@gmail.com inbox by topic and routes them: career topics to Andy, health topics to Cooper, MARS-owned items stay with MARS, unsure items escalate to Maxime. Self-contained dispatch logic with strict safety rules for mailbox mutations."
version: 3.0.0
author: MARS (revamped 2026)
license: MIT
required_skills: [google-workspace]
metadata:
  hermes:
    tags: [email, gmail, triage, multi-agent, dispatch]
    related_skills: [google-workspace]
---

# Email Triage

This skill sorts emails from the shared inbox according to topic and decides what to do with each message:

- `career` → dispatch to Andy (career-manager profile)
- `health` → dispatch to Cooper (health-coach profile)
- `MARS-owned` → handle locally (limited safe actions only)
- `unsure` → escalate directly to Maxime (never auto-archived or mutated)

The inbox polling cron loads this skill when it detects new mail. The skill performs the actual classification and routing.

**Core principle:**  
Only ever hand off a `message_id` plus a very short summary. The receiving profile is responsible for fetching the full message content using the `google-workspace` skill.

This skill is fully self-contained. It no longer requires a separate `agent-dispatch` skill.

## Classification

Every processed message must be classified into exactly one of the four categories above.

If classification is ambiguous or the model is not confident, the message **must** fall back to `unsure`.

## Dispatch (career / health)

When a message is classified as `career` or `health`, this skill is responsible for handing it off to the correct profile.

Preferred handoff (recommended):
- Create a task in the shared kanban board assigned to the target profile, containing the `email_id` and minimal context.

Lightweight alternative (when kanban is not suitable):
- Direct profile invocation: `hermes chat -p career-manager -q "Fetch and process Gmail message <id>. Short context: ..."`

After a successful handoff, the skill may archive + mark the original message as read (Inbox messages only). Non-Inbox targeted messages keep their current state.

## MARS-owned handling

Messages classified as `MARS-owned` are processed directly by this skill.

Allowed actions (keep them minimal and safe):
- Reading the full message
- Archiving clearly non-actionable automated mail (newsletters, receipts, etc.) that is still in the Inbox

Forbidden:
- Replying, forwarding, deleting, applying meaningful labels, or any high-impact change.

If a safe action is taken successfully on an Inbox message, it may be archived and marked read.

## Unsure handling

Messages classified as `unsure` must never be mutated by this skill.

- Leave the message exactly where it is (especially if it is still in the Inbox).
- Escalate to Maxime with the `message_id`, sender, subject, date, and a short reason why it was marked unsure.

This ensures the message remains visible on future sweeps until a human resolves it.

## Mutation Rules (strict)

- Only archive + mark read an Inbox message after a **successful** terminal outcome (confirmed dispatch to Andy/Cooper, or successful safe MARS-owned action).
- `unsure` messages: zero mutations ever.
- Any error or uncertainty on a specific message: leave that message untouched.
- Pre-run auth failure: zero mutations and escalate to Maxime.

## Targeted / Manual Use

The skill can also be invoked directly for a single message or a custom query (useful for re-processing or debugging):

- By `email_id`
- By arbitrary Gmail query (may include mail outside the Inbox)

Targeted runs follow the same classification and mutation rules.

## History / Revamp Notes

- Original versions combined triage logic with specific delegation transport.
- 2026 revamp made the skill self-contained: it owns classification by topic and the decision of where to route work (Andy / Cooper / MARS / Maxime).
- The old separate `agent-dispatch` contract has been retired.

## Safety

All mailbox changes go through the `google-workspace` skill. Failed or uncertain handoffs leave the original message untouched so the flow is repeatable and safe.
