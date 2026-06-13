---
name: career_job-seeking
description: "Career job-seeking hub for Andy. Job hunt, lead tracking, interview coaching, profile building, registry maintenance."
version: 2.0.0
author: Maxime Baudette
license: MIT
metadata:
  hermes:
    tags: [career, job-search, job-hunt, lead-tracking, interview, application]
    related_skills: [career_employment-optimizer]
---

# Career Job-Seeking Skill

Three interlocked missions: discover → pursue → land.

## MISSION REGISTRY

| Mission | File | Trigger |
|---|---|---|
| **Job Hunt** | `mission_job-hunt.md` | cron Mon 6:30am PT / "run job hunt" |
| **Lead Tracking** | `mission_lead-tracking.md` | Post-hunt handoff / "show pipeline" |
| Interview Coach | `mission_interview-coach.md` | interview_scheduled / "prep me" |
| Profile Building | `mission_profile-building.md` | "build profile" |
| Registry Maintenance | `mission_job-registry-maintenance.md` | cron daily 6am PT |

## ROUTING

| Maxime says | Run |
|---|---|
| "run job hunt", "weekly search" | Job Hunt |
| "show pipeline" | Lead Tracking P2 |
| "let's apply to #ID" | Lead Tracking P3 |
| "prep me for interview at X" | Interview Coach |
| "debrief my X interview" | Interview Coach P7 |
| "refresh / build profile" | Profile Building |
| "review my offer letter" | See `references/offer-letter-analysis.md` |
| "evaluate benefits" | See `references/contract-benefits-evaluation.md` |

## QUICK REFERENCE INDEX

| Topic | File | When to read |
|---|---|---|
| Communication format (cron) | `references/cron-output-format.md` | Before ANY cron output |
| Interview accuracy rules | `references/interview-coach-accuracy-rules.md` | Before Phase 1 of Interview Coach |
| Boundary violations | `references/boundary-violations.md` | Before ANY registry write |
| Operational safety | `references/operational-safety.md` | Before using tools |
| Competing offer leverage | `references/competing-offer-leverage.md` | Got competing offer? Read this. |
| Company intelligence | `references/intersect-company-intelligence.md` | Before interview prep |
| Registry maintenance | `references/registry-maintenance-gaps.md` | Before registry edits |
| Lead directory convention | `references/lead-directory-convention.md` | Creating lead files |
| Workspace paths | `references/workspace.md` | Path resolution quirks |
| Data contracts | `references/HANDOFFS.md` (historical; see mission specs + cross-file-consistency.md for current) | Schemas & handoff formats |
| Cross-file consistency | `references/cross-file-consistency.md` | Sync job_leads.json ↔ job_registry.json |
| Cron heartbeat protocol | `references/cron-heartbeat-protocol.md` | Hourly heartbeat procedures |
| Cron template resolution | `references/cron-template-variable-resolution.md` | When prompt has `{{mission}}` unresolved |
| KB archiving | `references/kb-archiving-workflow.md` | Archiving research to KB |
| Self-improvement | `SELF_IMPROVE.md` | Feedback protocol |
| Memory patterns | (see profile workspace/AGENTS.md Memory Architecture & Career Patterns) | Cross-profile architecture, scoring (Novelty etc.), pipeline/benchmark formats, cron realities, pitfalls (distilled from deprecated career-memory-management) |

## PROACTIVE BEHAVIOR

- After Job Hunt reply processing → auto-run Lead Tracking P1
- Pipeline stale (>7d last_action) → nudge Maxime
- high-score (>=4) not applied >7d → Telegram reminder
- Interview within 72h but >2h away → offer Interview Coach
- **Interview <2h away → do NOT offer, deliver prep immediately** (see `references/dual-interview-rapid-prep.md`)

## DATA FLOW

```
Job Hunt P4 (digest)  ──▸ job_hunt_flagged_pending.json (audit snapshot)
Job Hunt P6 (reply)   ──▸ job_hunt_flagged.json (scored entries)
                                     │
                                     ▼
                             Lead Tracking P1 (ingest)
                                     │
                                     ▼
Job Hunt ──▸ job_registry.json ◄── Registry Maintenance ◄── Lead Tracking (sync)
                 │                                               │
                 └────────── Lead Tracking ──▸ job_leads.json ──▸ Interview Coach
                                                       │
                                               memory/metrics.json
```

Full schemas & current handoff rules live in the individual mission_*.md files + `references/cross-file-consistency.md`. `HANDOFFS.md` is retained as historical/supplementary after the two-registry changes.

## FILE PATHS

Base: `/home/mars/.hermes/profiles/career-manager/workspace/`
See `references/workspace.md` for path resolution quirks.

## SKILL EVOLUTION GUARDRAILS

## SCHEDULED CRONS (Andy career-manager profile)

These cron jobs are deployed on mars under the `career-manager` profile. All use `workdir=/home/mars/.hermes/profiles/career-manager/workspace`.

| Cron Name | Schedule | Mission | Description |
|---|---|---|---|
| `heartbeat` | 0 7-19 * * * (hourly business hrs) | email-triage skill | Gmail inbox heartbeat — polls for digest replies and Maxime interactions |
| `Job-Search: Weekly Hunt` | 30 6 * * 1 (Mon 6:30 AM) | `mission_job-hunt.md` | Weekly job discovery — search + score + digest email |
| `Employment: Monthly Optimizer` | 0 6 1 * * (1st of month) | `career_employment-optimizer` | Monthly check: achievements gap, comp benchmark, career dev |
| `Job-Search: Registry Maintenance` | 20 6 * * * (daily 6:20 AM) | `mission_job-registry-maintenance.md` | Validate URLs, mark closed/filled offers, enrich salary data |
| `Job-Search: Lead Tracking` | 0 9,13 * * * (9 AM + 1 PM) | `mission_lead-tracking.md` | Ingest handoff → update pipeline → application prep → follow-ups |

**KB crons** (deployed via `KB/knowledge-ops/crons/setup-hermes-crons.sh`, not part of this skill):
- `KB: Dreaming` — 15 8,16 * * * — Memory consolidation + PR submissions
- `KB: Lean Check` — 15 7 * * * — MEMORY.md trimming via KB promotion

**Note:** The cron prompt may contain a generic `{{mission}}` template. On startup, follow `references/cron-template-variable-resolution.md` to deduce the correct mission and load its spec.

**DO NOT modify this file or any mission/reference file without explicit Maxime approval.**

- User feedback → record in `memory/feedback/<mission>_feedback.json` ONLY
- New tactics/rules → propose to Maxime; do NOT self-append to SKILL.md
- Reference-worthy content → write to `references/` via MARS review, not inline
- SKILL.md is a routing table ONLY — not a dumping ground for procedures
