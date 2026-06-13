# Cross-File Consistency — Sync Rules

**Skill:** `career_job-seeking`  
**Version:** 1.0.0

Ensures `job_registry.json` and `job_leads.json` stay in sync when Lead Tracking or Interview Coach change status, dates, or outcomes.

## Core Sync Rules

| Trigger (in `job_leads.json`) | Action on `job_registry.json` |
|---|---|
| Lead status → `applied` | Set `applied_date` = today on matching registry entry |
| Lead status → `interview_scheduled` | Set `status` = `interview_scheduled` on registry |
| Lead status → `offer` | Set `status` = `offer` on registry |
| Lead status → `rejected` or `withdrawn` | Set `status` = same on registry |
| Interview outcome recorded | Append to `notes` on registry (prefix with date) |
| Registry Maintenance marks `closed` | Sync `closed` to matching lead if exists |

## ID Convention

```
registry:  offers[].id              = "042" (zero-padded 3-digit string)
leads:     entries[].registry_id    = "042" (matches registry)
leads:     entries[].lead_id        = "lead_<company_slug>_042"
```

## Reconciliation Procedure

Run when metrics.json pipeline snapshot totals don't match registry counts:

1. Load both `job_registry.json` and `job_leads.json`
2. For each lead in job_leads with `status` in `{applied, interview_scheduled, offer, rejected, withdrawn}`:
   - Find matching registry entry by `registry_id`
   - If registry status differs → update registry to match lead
   - If `applied_date` set on lead but null on registry → copy to registry
3. For each registry entry with `status` = `closed`:
   - Find matching lead by `registry_id`
   - If lead exists and not closed → update lead to `closed`
4. Write both files back

## How Missions Use This

- **Lead Tracking Phase 3** (Application): When status moves to `applied`, sync `applied_date` to registry.
- **Lead Tracking Phase 5** (Interview Handoff): When `interview_scheduled`, sync status to registry.
- **Lead Tracking Phase 2** (Pipeline Update): When marking `rejected`/`withdrawn`, sync to registry.
- **Registry Maintenance Step 4**: When marking `closed` on registry, also close matching lead.
- **Interview Coach Phase 7** (Debrief): Append outcome to registry notes.
