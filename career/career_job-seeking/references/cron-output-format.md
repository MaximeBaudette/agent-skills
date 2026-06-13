# Cron Output Format Rules

**Source:** Maxime explicitly said "VERY chatty, too much" about the Lead Tracking cron output.

## Hard Rules

Any cron report or automated output delivery MUST follow these rules:

### Content
- **MAX 2 lines per item.** Company + role + status/action. NO salary, NO location, NO URLs, NO detail keys.
- **One-line TL;DR at top.** Summarize state in one line.
- **SILENT if nothing actionable.** If no interview today, no new email replies, no items Maxime hasn't seen → `[SILENT]`.

### Critical: [SILENT] must be EXACT

The framework detects `[SILENT]` by exact string match — it checks for `"[SILENT]"` (with square brackets, uppercase) in the agent's final response. Any variation WILL be delivered as a real message:

| Output | Detected? | Delivered? |
|--------|-----------|------------|
| `[SILENT]` | ✅ Yes | ❌ No (suppressed) |
| `SILENT` (no brackets) | ❌ No | ✅ Yes |
| `**SILENT**` (bold markdown) | ❌ No | ✅ Yes |
| `[silent]` (lowercase) | ❌ No | ✅ Yes |

**Never combine `[SILENT]` with report content.** The scheduler says: "Never combine [SILENT] with content — either report your findings normally, or say [SILENT] and nothing more." Mixing content + `[SILENT]` suppresses delivery and Maxime gets no report.

**Why agents get this wrong:** Backtick-wrapped `[SILENT]` in prompts (e.g., "output `[SILENT]`") makes the model interpret it as a code reference rather than literal output. It substitutes markdown formatting like `**SILENT**`. Fix: tell the model "output the EXACT literal string `[SILENT]` (with square brackets, no markdown, no bold)" and warn that variations get delivered.

### Sections to OMIT
- **No pipeline health section.** Skip metrics section entirely unless a threshold is breached (21d no new leads, stale >30d).
- **No stale item breakdown.** Replace multi-line stale lists with single line: `⚠️ ~N stale items from last hunt`.
- **No scored-item re-nudging.** Items already flagged before should not repeat. Only flag if score >=4 and pending >14d.

### When NOT to apply
These rules apply to cron reports and automated digests. They do NOT apply to:
- Interactive coaching sessions ("prep me for interview")
- Manual pipeline queries ("show me #010 details")
- Interview prep documents (those need full detail)
