# Lead Directory Convention

**Established:** 2026-05-24 (Intersect Power prep session)

## Rule

Each active lead gets a directory under `career/leads/`, not a flat file.

## Format

```
career/leads/<YYYY-MM>-<company-slug>-<role-slug>/
├── interview-prep.md    ← Full prep doc (company context, role, STAR stories, salary, questions, logistics)
├── role-analysis.md     ← Deep dive: mission breakdown, weakness defense, growth areas, benefits
└── pitch-coaching.md    ← Pitch analysis + revised version (if phone screen)
```

## Naming

- **Prefix:** `YYYY-MM` — year and month the lead was first prepped
- **Company slug:** lowercase, hyphenated, no articles
- **Role slug:** ~2-4 key words from title, lowercase, hyphenated

**Examples:**
- `2026-05-intersect-validation-engineer/`
- `2026-01-acme-senior-grid-engineer/`

## Why

- Scalable: each stage of prep adds a new file without renaming or clobbering
- Findable: `find` / `ls` by company or date works naturally
- Linkable: `workspace_path` in `job_leads.json` points to the directory

## Updating job_leads.json

When you create or rename a lead directory, update `workspace_path` in `job_leads.json` to the new path.
