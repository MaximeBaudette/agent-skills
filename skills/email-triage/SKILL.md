---
name: email-triage
description: Inbox sweep and targeted Gmail triage for MARS with delegation, self-processing, and user escalation.
homepage: https://github.com/MaximeBaudette/agent-skills
required_skills: [google-workspace, delegate]
---

# Email Triage

Triage individual Gmail messages for MARS. This skill replaces the old unread-only, keyword-only, memory-gated flow with Inbox-as-source-of-truth behavior.

## Purpose and scope

This skill classifies **individual Gmail messages** into exactly four outcomes:
- `health`
- `career`
- `MARS-owned`
- `unsure`

The skill works at the **message level, not the thread level**. Every fetch, classification, delegation, follow-up action, and mutation decision is based on a Gmail **message ID**, not a thread ID.

`health` and `career` are delegated through the reusable `delegate` skill.
`MARS-owned` is either handled by MARS directly or cleaned up if it is non-actionable.
`unsure` is escalated to Maxime directly from this skill and must **not** be routed through `delegate`.

Direct alerting to Maxime is an internal `email-triage` behavior, not a `delegate` call.
The MARS follow-up path is also internal to `email-triage`; it is a triage-owned execution path, not the external `delegate` skill.

## Modes

Invocation is resolved by selector presence:

- **no selector** (`email_id` absent and `query` absent) → run **Inbox sweep**
- **`email_id` only** → run a **targeted single-message** triage
- **`query` only** → run a **targeted query** triage
- **both selectors present** → **invalid invocation**; stop immediately with **no mutations**

### Inbox sweep

Inbox sweep mode uses the **current Inbox only**:

```text
in:inbox
```

Rules:
- Search `in:inbox` only.
- Include both **read and unread** mail.
- Process the matching results as **individual Gmail messages**.
- Do **not** use the old memory-based duplicate gate.
- Inbox membership is the **source of truth** for whether a message should be seen again on future sweeps.

### Targeted run

Targeted run uses **exactly one selector**:
- `email_id=<gmail_message_id>`
- `query=<gmail_query>`

Rules:
- Provide **exactly one selector**. If both are present, stop with no mutations.
- `email_id` targets one Gmail message by message ID.
- `query` matches **all messages**, including non-Inbox mail.
- A targeted `query` still processes results as **individual Gmail messages**, never as threads.

## Preconditions

Before doing anything else, run a Google Workspace auth check.

- If auth is valid, continue.
- If auth is not valid, **alert Maxime** and stop.
- A pre-run auth failure causes **zero mutations** across the run.
- Never attempt re-auth inside this skill.
- This alert is sent by `email-triage` itself and does not use `delegate`.

## Run semantics

This skill is **non-transactional**.

That means:
- each message is handled independently
- a failure on one message does not roll back successful work on earlier messages
- partial-run outcomes are acceptable
- selector/query enumeration failure leaves that selector expansion path untouched and stops that path
- per-message fetch failure leaves that message untouched and continues with others

Inbox sweep must not rely on any memory-based duplicate tracking. If a message is still in Inbox, it is eligible for future inbox sweeps. Inbox membership is the source of truth.

## Per-message workflow

For each selected Gmail message:

### 1. Fetch the message by Gmail message ID

Obtain the full message payload using the Gmail **message ID**.

If the per-message fetch fails:
- leave that message untouched
- continue with the remaining messages

### 2. Classify the message

Classify into exactly one of:
- `health`
- `career`
- `MARS-owned`
- `unsure`

If parsing or classification is ambiguous, incomplete, or malformed, **parse/classification failure** falls back to `unsure`.

### 3. Handle by outcome

#### Outcome: `health`

Invoke `delegate` with target `cooper`.

Required delegation shape:
- `target=cooper`
- `task_source=email-triage`
- `reference_id=<gmail_message_id>`
- lightweight context containing enough summary for Cooper to decide whether to fetch the message

If delegation succeeds:
- Inbox message: archive and mark read
- targeted non-Inbox message: keep its **current read state** and labels

If **delegate failure** occurs:
- leave the message untouched
- continue with the remaining messages

#### Outcome: `career`

Invoke `delegate` with target `andy`.

Required delegation shape:
- `target=andy`
- `task_source=email-triage`
- `reference_id=<gmail_message_id>`
- lightweight context containing enough summary for Andy to decide whether to fetch the message

If delegation succeeds:
- Inbox message: archive and mark read
- targeted non-Inbox message: keep its **current read state** and labels

If **delegate failure** occurs:
- leave the message untouched
- continue with the remaining messages

#### Outcome: `MARS-owned`

First decide whether the message is actionable for MARS.

##### Actionable `MARS-owned`

Invoke the **MARS follow-up workflow**, an internal triage-owned execution path.

MARS follow-up workflow contract:
- **minimum required input:** Gmail `message_id`
- **required behavior:** the workflow must re-fetch the message by Gmail message ID as an intentional isolation step before acting; any upstream summary/context is advisory only and may not replace this fetch
- **allowed actions:** read-only inspection plus low-risk mailbox hygiene that stays within triage scope
- **forbidden actions:** reply, send, delete, forward, move into Inbox, or any other high-impact change
- **minimum required output:** a concise summary of the actions taken, or a no-op summary when no safe action applies
- **success:** the safe action(s) complete and the workflow returns its summary
- **failure:** any fetch, inspection, or action error leaves the message untouched and the workflow reports failure

If the **MARS follow-up workflow** succeeds:
- Inbox message: archive and mark read
- targeted non-Inbox message: keep its **current read state** and labels

If **MARS follow-up failure** occurs:
- leave the message untouched
- continue with the remaining messages

##### Non-actionable `MARS-owned`

A non-actionable `MARS-owned` message does not need delegation or a follow-up workflow.

If it is still in Inbox:
- mark read
- archive

If it is a targeted non-Inbox message:
- keep its **current read state** and labels

#### Outcome: `unsure`

Message Maxime directly from triage.
Do **not** use `delegate` for `unsure` mail.

Direct escalation interface:

- **minimum required input:** Gmail `message_id` plus a short reason triage is unsure
- **minimum required output:** a delivered alert that clearly identifies the message and preserves the reason
- **success:** the alert is handed off to Maxime and recorded as sent
- **failure:** the alert cannot be delivered; leave the message untouched and continue

The escalation should include the Gmail message ID and a short explanation of why triage was unsure.

If user escalation succeeds:
- Inbox message: leave it in Inbox so it can **repeat on future Inbox sweeps while still in Inbox**
- Inbox message: do not archive it
- targeted non-Inbox message: keep its current read state and labels
- targeted non-Inbox message: do **not** move it into Inbox

If **user-escalation failure** occurs:
- leave the message untouched
- continue with the remaining messages

## Mutation rules

These rules are mandatory and explicit:

- Inbox messages archive/read on successful handling.
- Successful handling means: successful delegation, successful MARS follow-up, or successful classification as non-actionable `MARS-owned` while still in Inbox.
- `unsure` is not successful handling; keep the message where it is so Maxime can review it.
- targeted non-Inbox messages keep their **current read state** and labels on successful delegation.
- targeted non-Inbox messages keep their **current read state** and labels on successful MARS follow-up.
- targeted non-Inbox, non-actionable `MARS-owned` messages keep their **current read state** and labels.
- targeted non-Inbox `unsure` and failure cases do **not** move mail into Inbox.
- pre-run auth failure causes **zero mutations** across the run.

## Failure handling summary

- Pre-run auth failure → alert Maxime from `email-triage`, stop, zero mutations.
- Selector/query enumeration failure → stop that selector expansion path; no messages from that selector are mutated.
- Per-message fetch failure → leave that message untouched and continue.
- Parse/classification failure → classify as `unsure`.
- Invalid invocation (both selectors present) → stop immediately with no mutations.
- Delegate failure → leave the message untouched.
- MARS follow-up failure → leave the message untouched.
- User-escalation failure → leave the message untouched.
- One message failing must not block successful handling of other messages in the same run.

## Notes for replacing the old combined skill

This skill intentionally replaces the prior behavior.

Old behavior to remove from triage logic:
- unread-only search
- keyword-only routing assumptions
- shared-group delegation rules baked directly into triage
- memory-based duplicate gate

New behavior to enforce:
- Inbox sweep uses `in:inbox`
- Inbox sweep includes read and unread mail
- targeted run supports `email_id` or `query`
- `query` can match non-Inbox mail
- handling is message-level
- Inbox membership is the source of truth for repeat processing on future sweeps
