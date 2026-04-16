---
name: delegate
description: Reusable inter-agent delegation contract; responsible for delivering structured delegation requests from MARS to other sub-agents (Andy, Cooper) via the documented transport path.
version: 1.0.0
author: MARS
license: MIT
---

# Delegate (contract)

## Purpose and Scope

This SKILL documents the contract for a reusable "delegate" skill used to hand off tasks from MARS to other sub-agents. It defines required inputs, supported targets, transport details, success/failure semantics, and expected behaviour when the transport path fails. Scope: delivery of delegation messages only — this skill does NOT perform the delegated work.

## Supported targets

- andy
- cooper

## Required inputs

The delegate skill MUST accept these inputs (required inputs):

- target (string): one of `andy`, `cooper`
- task_source (string): origin of the task (e.g., `email-triage`)
- context (object|string): a short structured payload or summary useful to the target
- reference_id (string): canonical ID used to fetch the full artifact (e.g., Gmail message ID)

## Transport path (current)

The current transport path used by MARS to reach Andy and Cooper in Maxime's setup is posting messages to the shared Telegram group "My Team" (chat ID: -1003989798620) and mentioning the canonical handles `@andy` or `@cooper`. The delegate skill owns this transport path for now and documents its usage.

Example transport payload (conceptual):

- chat_id: -1003989798620
- text: "@andy — DELEGATE: task_source=email-triage reference_id=<id> context=<brief summary>"

## What to do when the transport path fails

If the transport path fails (e.g., Telegram API error, network, or bot token invalid):

- Retry policy: do up to N retries with exponential backoff (implementation detail left to runtime).
- On persistent failure: record a failure event in logs and in-memory state and return a failure response to the caller.
- If persistent failure occurs, escalate by creating an internal alert (not a surfaced message to Maxime) so operator tooling can notice; do NOT post a message directly to Maxime's primary channels.

If the transport path fails, the delegate skill should not mark the delegation as accepted.

## Success semantics

Success semantics: a delegation is considered successfully delivered when the transport path accepts the message (e.g., Telegram API returns HTTP 200 and message_id). Success means "accepted by transport path" — it does NOT mean the delegated task was completed by the target agent.

## Failure semantics

- Transient failures (temporary network or API error): treated as retries. The delegate skill should surface a failure response to the caller only after retry exhaustion.
- Permanent failures (invalid input, unauthenticated transport, missing target): return an explicit error to the caller with a human-readable reason and machine-readable code.
- When delegation is not accepted by transport, do not mark the item as dispatched in persistent memory.

## Not for surfacing messages to Maxime

Explicit: This skill is NOT for surfacing unsure emails or similar messages to Maxime. It is not a user-escalation channel. Do NOT use this skill to surface unclear items to `@mars` or other Maxime-facing channels.

## Expected behaviour and responsibilities

- Validate required inputs: `target`, `task_source`, `context`, `reference_id`. Missing required inputs → immediate error.
- Normalize `target` to one of the supported targets or return validation error.
- Produce a transport payload suitable for the current transport path and attempt delivery.
- On delivery success: return a machine-readable success envelope containing transport metadata (timestamp, transport_message_id) and do not assume task completion.
- On delivery failure: return an error envelope describing failure semantics above.

## Examples — how email-triage should invoke delegate

YAML example (conceptual):

```yaml
- skill: delegate
  inputs:
    target: andy
    task_source: email-triage
    context: "From: recruiter@example.com; Subject: Senior Engineer; Deadline: 2026-04-20"
    reference_id: "GMAIL_MSG_1234567890"
```

JSON example (programmatic):

{
  "skill": "delegate",
  "inputs": {
    "target": "cooper",
    "task_source": "email-triage",
    "context": {"snippet": "Lab results attached, appointment 2026-04-21"},
    "reference_id": "GMAIL_MSG_987654321"
  }
}

## Notes

- Keep payloads minimal; include only summary context and a reference_id so the target can fetch the full artifact independently.
- The delegate skill owns the transport path documentation and retry/escalation behaviour; runtime implementations may vary but must adhere to this contract.

