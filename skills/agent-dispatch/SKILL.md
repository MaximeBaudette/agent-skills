---
name: agent-dispatch
description: Reusable inter-agent dispatch contract; responsible for delivering structured handoff requests from MARS to other sub-agents (Andy, Cooper) via the documented transport path.
version: 1.0.0
author: MARS
license: MIT
---

# Agent Dispatch (contract)

## Purpose and Scope

This SKILL documents the contract for a reusable `agent-dispatch` skill used to hand off tasks from MARS to other sub-agents. It defines required inputs, supported targets, success/failure semantics, and expected behaviour when the transport path fails. Scope: delivery of dispatch messages only — this skill does NOT perform the dispatched work.

## Supported targets

- andy
- cooper

## Required inputs

The `agent-dispatch` skill MUST accept these inputs:

- target (string): one of `andy`, `cooper`
- task_source (string): origin of the task (e.g., `source-system`)
- context (object|string): a short structured payload or summary useful to the target (see "Context shape" below)
- reference_id (string): canonical ID used to fetch the full artifact (e.g., transport-agnostic artifact identifier like `artifact_123456`)


## Context shape (recommended)

The `context` input is intentionally lightweight. It MAY be either a plain string summary or a small JSON object. Do not embed large artifacts — include a `reference_id` so the target agent can fetch the full item.

Keep `context` aggressively short. Do not include score-by-score examples, long link lists, or copied message bodies.

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
  "task_source": "source-system",
  "reference_id": "artifact_1234567890"
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
  "message": "Transport API returned 401: authentication failed",
  "retryable": false,
  "details": { "http_status": 401 },
  "target": "cooper",
  "task_source": "source-system",
  "reference_id": "artifact_987654321"
}
```


## Expected behaviour and responsibilities

- Validate required inputs: `target`, `task_source`, `context`, `reference_id`. Missing required inputs → immediate error (use `code: "invalid_input"`).
- Normalize `target` to one of the supported targets or return validation error.
- Produce a transport payload suitable for the chosen transport and attempt delivery.
- On delivery success: return the success envelope (see above). Do NOT assume task completion by the target agent.
- On delivery failure: return the error envelope describing failure semantics above.
- Do NOT mark dispatch as "accepted" until transport indicates success.

## Current runtime transport — Hermes profile query

This is the **live runtime transport** for this host.

Use Hermes profile queries, not a conceptual no-op and not a Telegram group handoff.

Target mapping:

- `andy` -> profile `career-manager`
- `cooper` -> profile `health-coach`

Required runtime behavior:

1. Validate the input envelope first.
2. Map `target` to the corresponding Hermes profile.
3. Build a short delegation prompt that includes:
   - `task_source`
   - `reference_id`
   - the provided `context`
   - a direct instruction to fetch the full artifact using `reference_id` when needed
   - only the minimum summary needed to route the task; for `email-triage`, prefer wording like "Maxime replied with scoring feedback on the weekly job hunt email"
4. Execute the handoff with Hermes CLI:

```bash
hermes chat -p <profile> -q "<delegation prompt>"
```

Use a generous command timeout for Hermes profile queries. For `email-triage`, the minimum recommended timeout is 180 seconds.

5. Treat the dispatch as successful **only if**:
   - the Hermes command exits with status `0`, and
   - stdout contains a non-empty response from the target profile

Recommended prompt shape:

```text
Delegated task from MARS.
target=<target>
task_source=<task_source>
reference_id=<reference_id>
context=<short summary or compact JSON>

Fetch the full artifact using reference_id if needed, process it using your own workflow, and reply with a concise summary.
```

For `email-triage`, keep `context` to one or two sentences and rely on `reference_id` for the full message. Do not include score-by-score examples, long link lists, or copied message bodies.

Recommended success envelope for this runtime transport:

```json
{
  "status": "delivered",
  "timestamp": "2026-04-17T01:00:00Z",
  "transport": {
    "name": "hermes-profile-query",
    "details": { "profile": "career-manager" }
  },
  "transport_message_id": null,
  "target": "andy",
  "task_source": "email-triage",
  "reference_id": "artifact_123456"
}
```

If the Hermes query exits non-zero, produces empty output, or otherwise cannot confirm delivery, return an error envelope and do **not** claim the task was delivered.


## Failure semantics

- Transient failures (e.g., temporary network or API errors) should be reflected with `retryable: true` in the error envelope so callers can decide to retry.
- Permanent failures (e.g., invalid input, authentication errors, missing target) should be reflected with `retryable: false` and an appropriate `code`.
- Implementations must not mark a dispatch as delivered unless the transport indicates success.
- A conceptual or narrated handoff without a successful transport result is a failure, not a delivery.


## Examples — invocation examples

YAML example (conceptual):

```yaml
- skill: agent-dispatch
  inputs:
    target: andy
    task_source: source-system
    context: "Short summary: candidate message; Subject: Senior Engineer; Deadline: 2026-04-20"
    reference_id: "artifact_123456"
```

JSON example (programmatic):

```json
{
  "skill": "agent-dispatch",
  "inputs": {
    "target": "cooper",
    "task_source": "external-system",
    "context": {"snippet": "Lab results attached, appointment 2026-04-21"},
    "reference_id": "artifact_987654"
  }
}
```

## Notes

- Keep payloads minimal; include only summary context and a reference_id so the target can fetch the full artifact independently.
- This document records the current runtime transport path and the required delivery contract. Runtime implementers must ensure they return the machine-readable envelopes described above.
