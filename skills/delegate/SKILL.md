---
name: delegate
description: Reusable inter-agent delegation contract; responsible for delivering structured delegation requests from MARS to other sub-agents (Andy, Cooper) via the documented transport path.
version: 1.0.0
author: MARS
license: MIT
---

# Delegate (contract)

## Purpose and Scope

This SKILL documents the contract for a reusable "delegate" skill used to hand off tasks from MARS to other sub-agents. It defines required inputs, supported targets, success/failure semantics, and expected behaviour when the transport path fails. Scope: delivery of delegation messages only — this skill does NOT perform the delegated work.

## Supported targets

- andy
- cooper

## Required inputs

The delegate skill MUST accept these inputs (required inputs):

- target (string): one of `andy`, `cooper`
- task_source (string): origin of the task (e.g., `email-triage`)
- context (object|string): a short structured payload or summary useful to the target (see "Context shape" below)
- reference_id (string): canonical ID used to fetch the full artifact (e.g., Gmail message ID)


## Context shape (recommended)

The `context` input is intentionally lightweight. It MAY be either a plain string summary or a small JSON object. Do not embed large artifacts — include a `reference_id` so the target agent can fetch the full item.

Recommended minimal object shape (informational, not required):

- title (string): short human-facing title
- snippet (string): 1-2 sentence summary
- metadata (object): small map of extra fields (e.g., {"deadline": "2026-04-20"})

This keeps the contract simple while making it clear how to use `context` in practice.

## Success and error (machine-readable output)

Implementations MUST return a deterministic, machine-readable envelope on success or error. This makes downstream automation and auditing reliable.

Success envelope (example fields):

- status: "delivered" (string)
- timestamp: ISO-8601 timestamp (string)
- transport: object {
  - name: string (e.g., "telegram")
  - details: object (transport-specific metadata)
}
- transport_message_id: string|null (ID returned by transport)
- target: string (normalized target)
- task_source: string
- reference_id: string

JSON example (success):

```json
{
  "status": "delivered",
  "timestamp": "2026-04-15T12:34:56Z",
  "transport": { "name": "telegram", "details": { "chat_id": -1003989798620 } },
  "transport_message_id": "1234567890",
  "target": "andy",
  "task_source": "email-triage",
  "reference_id": "GMAIL_MSG_1234567890"
}
```

Error envelope (example fields):

- status: "error" (string)
- code: string (machine-readable error code, e.g., `invalid_input`, `transport_error`, `auth_error`, `not_found`)
- message: human-readable explanation (string)
- retryable: boolean (true if caller may retry)
- details: optional object for transport or validation metadata
- target, task_source, reference_id: echoed where applicable

JSON example (error):

```json
{
  "status": "error",
  "code": "transport_error",
  "message": "Telegram API returned 401: bot token invalid",
  "retryable": false,
  "details": { "http_status": 401 },
  "target": "cooper",
  "task_source": "email-triage",
  "reference_id": "GMAIL_MSG_987654321"
}
```


## Expected behaviour and responsibilities

- Validate required inputs: `target`, `task_source`, `context`, `reference_id`. Missing required inputs → immediate error (use `code: "invalid_input"`).
- Normalize `target` to one of the supported targets or return validation error.
- Produce a transport payload suitable for the chosen transport and attempt delivery.
- On delivery success: return the success envelope (see above). Do NOT assume task completion by the target agent.
- On delivery failure: return the error envelope describing failure semantics above.
- Do NOT mark delegation as "accepted" until transport indicates success.

## Implementation note — current transport (Telegram)

This section records the transport path currently used in MARS for reaching Andy and Cooper. It is an implementation note and not part of the core contract. Runtime implementations MAY use different transports, but they MUST still satisfy the contract above (inputs, validation, and machine-readable outputs).

Current practice in this repository: post a message to the shared Telegram group "My Team" (chat ID: -1003989798620) and mention the canonical handles `@andy` or `@cooper`.

Conceptual transport payload example:

- chat_id: -1003989798620
- text: "@andy — DELEGATE: task_source=email-triage reference_id=<id> context=<brief summary>"

Implementation guidance (non-normative):
- The contract requires the error envelope to include a `retryable` boolean so callers can decide whether to retry.
- Transport wiring (authentication, retry/backoff policies, logging, and alerting) is a runtime concern and should be implemented according to the host environment's operational practices. These concerns are intentionally out of scope for the delegate contract.


## Failure semantics

- Transient failures (e.g., temporary network or API errors) should be reflected with `retryable: true` in the error envelope so callers can decide to retry.
- Permanent failures (e.g., invalid input, authentication errors, missing target) should be reflected with `retryable: false` and an appropriate `code`.
- Implementations must not mark a delegation as dispatched unless the transport indicates success.


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

```json
{
  "skill": "delegate",
  "inputs": {
    "target": "cooper",
    "task_source": "email-triage",
    "context": {"snippet": "Lab results attached, appointment 2026-04-21"},
    "reference_id": "GMAIL_MSG_987654321"
  }
}
```

## Notes

- Keep payloads minimal; include only summary context and a reference_id so the target can fetch the full artifact independently.
- This document records the current transport path and recommended operational behaviour. Runtime implementers own the actual transport wiring and must ensure they return the machine-readable envelopes described above.
