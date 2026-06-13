# File Path Conventions & Pitfalls (Health-Coach Profile)

See `workspace/AGENTS.md` (active when CWD=workspace/) for general operational rules, hard blocks, KB ownership, and high-level workflows. This is a supporting reference for path resolution only.

## CWD
- Tool cwd: `/home/mars/.hermes/profiles/health-coach/workspace/`
- All relative paths in mission files and skill docs resolve from this directory.
- **Do NOT prefix relative paths with `workspace/`** — it causes double-nesting (e.g., `labs.db` resolves to `/home/mars/.hermes/profiles/health-coach/workspace/workspace/labs.db`).

## Absolute Path Rule
Use absolute paths for these critical files:
- `/home/mars/.hermes/profiles/health-coach/workspace/maximes_location` — lat,lon; **external auto-update ONLY — NO EDIT**
- `/home/mars/.hermes/profiles/health-coach/workspace/archive/pollen_log.md` — append-only pollen history
- `/home/mars/.hermes/profiles/health-coach/workspace/labs.db` — canonical lab database

**Health snapshot pages (active_symptoms, lab_results, health_summary, treatment_plan, differential_diagnostic) have no local copies in the profile.**
They live only in Prime Radiant as cooper-owned pages under `health/snapshot/*`.
Access them exclusively via the knowledge-base skill (`kb_get_page` / `authoritative_push`).
The personal convenience symlink lives at `/home/mars/all_docs_quick-access/health-snapshot` (points to the KB dir).

For all other files, relative paths from CWD are preferred:
- `memory/` — batch pipeline state files and flags
- `archive/` — append-only logs and legacy snapshot archives
- `labs.db` — canonical lab database
- `state.json` — batch lifecycle state
- `AGENTS.md` — workspace-level operational rules (see workspace/AGENTS.md)

## Relative Path Behavior
All relative paths in mission files and docs resolve from:
```
/home/mars/.hermes/profiles/health-coach/workspace/
```

Examples:
- `labs.db` -> /home/mars/.hermes/profiles/health-coach/workspace/labs.db
- `memory/health_refresh_flags.json` -> /home/mars/.hermes/profiles/health-coach/workspace/memory/health_refresh_flags.json
- `state.json` -> /home/mars/.hermes/profiles/health-coach/workspace/state.json
- `archive/pollen_log.md` -> /home/mars/.hermes/profiles/health-coach/workspace/archive/pollen_log.md

(Old `snapshot/*.md` examples removed; those 5 pages are now exclusively KB `health/snapshot/*` — see workspace/AGENTS.md and concierge-doc data-contracts.md.)

## File Ops Protocol
1. `read_file` FIRST (verify content/exists). For KB pages use `kb_get_page` first.
2. Logs: read + append (write full old + new entry). **NEVER overwrite.**
3. Pitfall (May 8 loss): Blind `write_file` clobbered Apr-May pollen history.
