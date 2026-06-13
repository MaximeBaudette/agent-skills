# Mission: batch-poll

**Cron:** `cc496c1788e0` | `*/30 6-22 * * *` (every 30 min, 6 AM – 10 PM PT) | delivery: local  
**Authoritative cron entrypoint:** `scripts/cron_gate_batch_poll.py`  
**Silent rule:** If the gate returns `{"wakeAgent": false, "kind": "idle"}` or `{"wakeAgent": false, "kind": "processing"}`, stop there. Concierge-doc is not loaded on that path.

This mission file is authoritative for:

1. **Manual/query use** — e.g. “what’s my batch status?”
2. **Agent-facing follow-up after the gate wakes the agent** — i.e. when `scripts/cron_gate_batch_poll.py` returns `wakeAgent: true`

It is **not** the cron entrypoint anymore.

See `workspace/AGENTS.md` for the owned KB pages rules.

---

## Cron Runtime Reality

Cron job `cc496c1788e0` runs `scripts/cron_gate_batch_poll.py` first.

That gate script:

- reads `state.json` directly
- decides idle vs inflight without importing legacy batch_poll
- imports and runs internal poll logic only after confirming an inflight combined batch
- emits one of four payload shapes:

```json
{"wakeAgent": false, "kind": "idle"}
{"wakeAgent": false, "kind": "processing"}
{"wakeAgent": true, "kind": "completion", "message": "...", "results": [...]}
{"wakeAgent": true, "kind": "error", "message": "...", "results": [...]}
```

### Cron handling rules

- If `wakeAgent` is `false`: remain silent. Do not load this mission file. Do not re-run poll.
- If `wakeAgent` is `true`: use the prepared payload from the gate. Do not re-poll xAI and do not re-run poll logic.

---

## Agent Follow-Up After `wakeAgent: true`

### Completion payload

Deliver the gate-provided completion message. The gate has already parsed the xAI batch result and performed the `authoritative_push` directly to the owned KB pages `health/snapshot/*` (no local snapshot files were written or exist in the profile).

Typical message:
```
🧬 Health snapshots updated!
• Health summary refreshed
• Treatment plan updated
• Differential diagnostic updated

Updates committed to Prime Radiant (health/snapshot/* owned by cooper).
```

The `results` (if provided by the gate) will reference the KB slugs that were pushed.

No further local file handling or "sync" step is needed — the gate already did the authoritative updates.

If the user asks for the current content, use `kb_get_page("health/snapshot/health_summary")` etc. in your response.

### Error payload

Deliver the gate-provided error message as-is:

```
⚠️ Health batch error: ...
```

Use `results` for supporting detail if needed, but do not mutate batch state here unless a separate operator workflow explicitly calls for it.

---

## Manual / Query Mode

When Maxime asks about batch status or the latest health snapshot refresh:

1. Read `state.json`
2. Inspect the combined batch fields:
   - `batches.combined.status`
   - `batches.combined.request_id`
   - `batches.combined.submitted_at` (if present)
   - top-level `xai_batch_id` for container identity
3. If helpful, read the current batch-owned snapshot pages for context via KB:
   - `kb_get_page("health/snapshot/health_summary")`
   - `kb_get_page("health/snapshot/treatment_plan")`
   - `kb_get_page("health/snapshot/differential_diagnostic")`

### Manual/query guardrails

- Do not claim this mission is the cron entrypoint
- Do not tell maintainers that cron always loads concierge-doc first
- Do not re-run gate logic just to answer a status question unless explicitly asked to perform an operator-style poll

---

## Key Paths (relative to profile root)

| Path | Purpose |
|---|---|
| `scripts/cron_gate_batch_poll.py` | Authoritative cron gate for `cc496c1788e0`. Parses xAI batch result and directly calls `authoritative_push` to the owned KB pages `health/snapshot/*` (no local writes). |
| `scripts/batch_poll.py` | (Legacy/internal only) Heavy logic used by the gate after confirming inflight batch. |
| `state.json` | Batch lifecycle state: status, `request_id`, timestamps, `xai_batch_id` |
| `health/snapshot/health_summary` (Prime Radiant only) etc. | The owned authoritative masters for the batch-generated snapshots. Updated directly by the gate via `authoritative_push`. Historical versions via KB git (no local archive/snapshots/ for active use). |
