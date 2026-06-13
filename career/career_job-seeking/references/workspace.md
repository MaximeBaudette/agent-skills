# Workspace Reference — career_job-seeking Skill

**Agent:** Andy (career-manager)
**Profile base:** `/home/mars/.hermes/profiles/career-manager/`
**Workspace root:** `/home/mars/.hermes/profiles/career-manager/workspace/`

---

## Directory Structure

```
workspace/
├── career/
│   ├── profile/
│   │   └── (profile)          ← Prime Radiant — Maxime's full career profile (target roles, keywords, deal-breakers)
│   │   └── (cv)         ← Prime Radiant — CV bullet bank for tailoring cover letters / applications
│   └── leads/
│       ├── <company>_<role>_application.md    ← per-lead application packages
│       └── <company>_<role>_interview_prep.md ← per-lead interview prep docs
└── memory/
    ├── job_registry.json       ← master registry of all discovered job offers (schema v1.1)
    ├── job_leads.json ← active application pipeline (schema v1.0)
    ├── metrics.json            ← cross-mission aggregate stats
    ├── weekly/
    │   ├── YYYY-MM-DD_local.json         ← Phase 1 results (Oakland/remote)
    │   ├── YYYY-MM-DD_regional.json      ← Phase 2 results (Bay Area)
    │   ├── YYYY-MM-DD_relocation.json    ← Phase 3 results (relocation tier)
    │   ├── YYYY-MM-DD_run_status.json    ← phase-by-phase progress tracker
    │   ├── YYYY-MM-DD_digest_sent.flag   ← idempotency flag (empty file)
    │   └── YYYY-MM-DD_digest_thread.json ← Gmail thread info for reply processing
    ├── handoffs/
    │   ├── job_hunt_flagged.json         ← scored leads ready for lead tracking ingestion
    │   ├── job_hunt_flagged_pending.json ← snapshot at digest-send time (audit trail)
    │   ├── job_leads.json        ← interview-scheduled leads for interview coach
    │   └── profile_signals.json          ← market signals and profile update suggestions
    ├── feedback/
    │   ├── job_hunt_feedback.json        ← feedback entries for job hunt mission
    │   ├── lead_tracking_feedback.json   ← feedback entries for lead tracking mission
    │   ├── interview_coach_feedback.json ← debrief records + feedback for interview coach
    │   └── learned_prefs.md           ← promoted cross-mission preferences
    └── logs/
        ├── handoff_warnings.log          ← staleness warnings, handoff issues
        └── audit.log                     ← security events (injection attempts, etc.)
```

---

## File Permissions (Andy's `file` tool scope)

Andy's `file` tool is restricted to:
- `career/profile/*` — no longer on filesystem (use Prime Radiant)
- `career/leads/*` — read + write
- `memory/*` — read + write (all subdirectories)

**Never allowed:**
- Paths outside `workspace/`
- `../` path traversal
- System paths, home directory root

---

## Tool Reference

### `web_search`
Tavily-powered search. No special configuration needed.
```
web_search(query="senior DER integration engineer Oakland 2026")
```
Returns: list of results with title, url, snippet, date.

### `browser`
View-only HTML fetcher. No JavaScript execution. No form submission. No authentication.
```
browser(url="https://example.com/job/123")
```
Returns: plain text content of the page.
Use for: reading job descriptions, company pages, public info.
Never use for: authentication, form fills, anything requiring interaction.

### `file`
Read/write files within allowed workspace paths.
```python
# Use absolute paths — relative workspace/... paths fail from Hermes session CWD
file(action="read", path="/home/mars/.hermes/profiles/career-manager/workspace/memory/job_registry.json")
file(action="write", path="/home/mars/.hermes/profiles/career-manager/workspace/memory/job_registry.json", content="...")
file(action="read", path="/home/mars/.hermes/profiles/career-manager/workspace/memory/weekly/")  # list directory
```
Use absolute paths from workspace root ONLY. Relative paths (workspace/...) are unreliable across sessions.

### `email`
Gmail operations via Google Workspace skill.
```
# Send email
email(action="send", to="maxime+hireme@baudette.fr", subject="...", body="...")

# List messages in thread
email(action="list_thread", thread_id="...")

# Get message body
email(action="get_message", message_id="...")

# Archive thread (mark read, remove from INBOX)
email(action="archive", thread_id="...")
```
Weekly digest send is PRE-APPROVED — no confirmation gate.
All other sends require CONFIRMATION REQUIRED from Maxime.

### `code_execution`
Python only. No network access. No system packages. Local file I/O allowed.
```python
# Run generate_digest.py
exec(open('/home/mars/.hermes/profiles/career-manager/skills/career_job-seeking/scripts/generate_digest.py').read())

# Read the output
with open('/tmp/digest_body.txt') as f:
    body = f.read()
print(body)

# JSON manipulation example
import json
from pathlib import Path

registry_path = Path('/home/mars/.hermes/profiles/career-manager/workspace/memory/job_registry.json')
with open(registry_path) as f:
    registry = json.load(f)
print(f"Total offers: {len(registry['offers'])}")
```

### `message`
Send Telegram notifications.
```
message(action="send", channel="telegram", target="7002352930", topic_id="237", message="...")
```
Always use `target: "7002352930"` and `topic_id: "237"` for Andy's career updates.

---

## Key File Schemas (Quick Reference)

### job_registry.json
```json
{"schema_version": "1.1", "last_id": 42, "offers": [
  {"id": "042", "title": "...", "company": "...", "location": "...", "url": "...",
   "salary_range": "...", "tier": 1, "discovered_date": "YYYY-MM-DD",
   "match_score": 8, "maxime_score": null, "score_date": null,
   "status": "active", "applied_date": null, "notes": ""}
]}
```

### job_leads.json
```json
{"schema_version": "1.0", "entries": [
  {"lead_id": "lead_acme_042", "registry_id": "042", "title": "...", "company": "...",
   "location": "...", "tier": 1, "url": "...", "salary_range": "...", "maxime_score": 4,
   "status": "shortlisted", "date_shortlisted": "YYYY-MM-DD", "date_applied": null,
   "last_action": "YYYY-MM-DD", "contact_name": null, "contact_email": null,
   "interview_date": null, "application_package": null, "notes": ""}
]}
```

### job_hunt_flagged_pending.json
Audit snapshot written at digest-send time (Phase 4). Schema per references/handoff-pending-contract.md.
```json
{"schema_version": "1.0", "generated_date": "YYYY-MM-DD", "digest_sent_to": "maxime+hireme@baudette.fr", "offers": [
  {"registry_id": "042", "title": "...", "company": "...", "location": "...",
   "tier": 1, "url": "...", "salary_range": "...", "score": 8}
]}
```

### job_hunt_flagged.json
Post-reply file (Phase 6). Contains only entries Maxime scored >= 1. Schema per references/HANDOFFS.md §Handoff File 1.

### job_leads.json
```json
{"schema_version": "1.0", "entries": [
  {"entry_id": "lt_YYYY-MM-DD_001", "lead_id": "lead_acme_042", "company": "...",
   "role_title": "...", "interview_type": "phone_screen", "interview_date": "YYYY-MM-DD",
   "interviewer": "...", "context_snapshot": {"cv_version_used": "...",
   "cover_letter_ref": "...", "key_talking_points": [], "known_concerns": []},
   "interview_outcome": null}
]}
```

---

## Hard Constraints (never violate)

| Constraint | Details |
|---|---|
| No shell commands | Andy has no terminal access |
| No Composio | Replaced entirely by `web_search` (Tavily) |
| No `gws` CLI | Use `email` tool and `file` tool instead |
| No `gws auth login/logout/setup` | Hard block — would destroy credentials |
| No `exec()` for shell | `code_execution` is Python-only, no subprocess with shell=True |
| CONFIRMATION REQUIRED | Any email except weekly digest needs Maxime's approval |
| No profile auto-update | Market signals → suggest only; never modify without "confirm update: yes" |
| No `../` path traversal | File tool scope is workspace/ only |

---

## Tool Quirks & Known Behaviors (Observed)

### `search_files` vs. `read_file` path resolution — updates

**Current finding (2026-05-26):** Both `read_file` and `search_files` with relative `workspace/...` paths fail from the Hermes session CWD (`/home/mars/.hermes/hermes-agent/`). The only reliable path is the absolute profile workspace path:

```
/home/mars/.hermes/profiles/career-manager/workspace/memory/job_leads.json
```

Earlier guidance suggesting `./memory/...` may work from some CWD states but is not reliable across sessions. Always use the full absolute path with the profile base.

**Resolution:** The SKILL.md FILE PATHS section now explicitly documents the absolute-path convention and base directory.

**When in doubt:** Start with `read_file` using the full absolute path under `/home/mars/.hermes/profiles/career-manager/workspace/`. If that fails, check `search_files(pattern="*", path="...")` with increasing path segments to discover where your session's CWD actually points.
