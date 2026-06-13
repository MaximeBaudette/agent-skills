# Actual metrics.json Schema (Observed 2026-04-23)

This document records the **real on-disk structure** of `memory/metrics.json` as observed during maintenance runs. It supplements `../HANDOFFS.md`, which documents an idealized/future schema.

## Motivation

During the 2026-04-23 Job Registry Maintenance run, two script failures occurred because the actual file structure differs from the idealized schema in HANDOFFS.md:

1. `TypeError: can only concatenate list (not "int") to list` — `metrics['job_hunt']['maintenance_runs']` is a **list of dicts**, not a scalar.
2. `AttributeError: 'str' object has no attribute 'get'` — `job_registry.json` is a **dict** with `"offers"` key, not a flat list.

## Actual metrics.json Structure

```json
{
  "job_hunt": {
    "runs": [
      {
        "date": "YYYY-MM-DD",
        "new_offers": 5,
        "total_unreviewed": 12,
        "email_sent": true
      }
    ],
    "maintenance_runs": [
      {
        "date": "YYYY-MM-DD",
        "total_checked": 11,
        "stale_marked": 2,
        "salary_enriched": 4,
        "notes_added": 3
      }
    ]
  },
  "last_hunt": "YYYY-MM-DD",
  "job_registry_maintenance": [
    {
      "date": "YYYY-MM-DD",
      "total_checked": 11,
      "stale_marked": 2,
      "salary_enriched": 4,
      "notes_added": 3
    }
  ]
}
```

## Critical Differences from HANDOFFS.md

| Field | HANDOFFS.md Claims | Reality |
|---|---|---|
| `schema_version` | `"1.0"` | **Does NOT exist** |
| `job_hunt.maintenance_runs` | Not documented | **List of dicts** (not scalar) |
| `job_registry_maintenance` | Not documented | **Top-level list of dicts** |
| `lead_tracking` | Documented | **May not exist** |
| `interview_coach` | Documented | **May not exist** |
| `job_hunt.runs[].phases_run` | Documented | **Does NOT exist** |

## Safe Access Pattern for Scripts

Always inspect structure before mutating:

```python
import json

with open(metrics_path) as f:
    metrics = json.load(f)

# Safe: append to list
metrics.setdefault('job_registry_maintenance', []).append({
    "date": today,
    "total_checked": n,
    "stale_marked": s,
    "salary_enriched": sal,
    "notes_added": notes
})

# Safe: check before assuming nested keys exist
if 'lead_tracking' in metrics:
    metrics['lead_tracking']['pipeline_snapshot']['date'] = today
```

## job_registry.json Safe Access

```python
with open(registry_path) as f:
    registry = json.load(f)

# WRONG: assumes flat list
# for job in registry: ...

# CORRECT: access the offers array
offers = registry['offers']
for job in offers:
    ...
```

## Related

- `../HANDOFFS.md` — idealized inter-mission data contracts
- `../SKILL.md` — skill routing and workspace map
