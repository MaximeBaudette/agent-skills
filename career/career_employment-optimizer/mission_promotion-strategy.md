# Mission: Promotion Strategy

Assess readiness for next level, build promotion case, optimize timing, and prepare salary negotiation. Absorbs all salary-negotiation content.

---

## TRIGGER

User says: "am I ready for promotion", "build promotion case", "get promoted", "I want a raise", "salary negotiation", or comp gap >= 15%.

## STARTUP CHECK

1. Read memory/employment_status.json. If unemployed -> STOP.
2. Read the owned career profile via `kb_get_page("career/profile")` (per the profile AGENTS.md instructions) for role, level, tenure, comp.
3. Read memory/promotion_case.md for prior assessments.

## PROCEDURE

### 1. Readiness Assessment

- Research next-level expectations (internal docs or levels.fyi).
- Inventory evidence: achievements from last 4 quarters mapped to next-level competencies. Score each: Strong/Some/No Evidence.
- Gap analysis: for each gap, identify opportunity type and timeline.

### 2. Readiness Score (1-10)

| Factor | Weight | Scoring |
|---|---|---|
| Achievement evidence | 35% | % of competencies with Strong Evidence |
| Tenure at level | 15% | <12mo=3, 12-18=5, 18-24=7, 24+=10 |
| Org-level impact | 20% | % of achievements at org/industry level |
| Manager support signals | 15% | Inferred from context |
| Market leverage | 15% | Comp gap from Market Comp Research |

8-10=Ready now, 5-7=Close (target next cycle), 1-4=Early (revisit 6mo).

### 3. Build Promotion Case (if score >= 5)

Write to memory/promotion_case.md under ## Promotion Case - [Date]:
Evidence by competency, Impact summary (narrative), Timeline recommendation, Risk factors, Supporting materials.

### 4. Timing Advice

Score 8+ and review <2mo -> push now. 5-7 and review <2mo -> fill gaps urgently. <5 -> target next cycle. 8+ no review -> ask about out-of-cycle. 24+ months -> escalate urgency.

### 5. Salary Negotiation (score >= 5)

**Pre-negotiation:** Read memory/salary_research.json (P50, P75). Map top 3 achievements to dollar impact. Align with review/budget cycle.

**Talking points:**
"Based on [achievement X] which delivered [Y], and market data showing [P50-P75] for comparable roles, I am requesting [target]."

**Objection handling:** Budget tight -> propose phased or mid-cycle review. Revisit at review -> set specific milestones. Need more evidence -> define measurable targets. Silence 2 weeks -> follow up once, then flag as bottleneck.

**Post-negotiation:**
- Success: log achievement, update employment_status.json with new comp.
- Deferred: log timeline to promotion_case.md, set check-back.
- Rejected/no plan: flag as stalled -> triggers 18-month alert + external benchmarking offer.

### 6. Post-Promotion

Congratulate, log achievement, update employment_status.json, update the owned career profile page via authoritative_push (per the profile AGENTS.md instructions for Prime Radiant `career/profile`), archive old case. Offer salary benchmarking for new level.

## OUTPUT

- Promotion case appended to memory/promotion_case.md
- Readiness score + recommendation sent to user
- Salary talking points (if applicable)

## EDGE CASES

- No comp data available: run Market Comp Research first.
- User wants external offers as leverage: CONFIRMATION REQUIRED before cross-invoking career_job-seeking.
- Promotion not possible (reorg/freeze): acknowledge and focus on skill building.
- 24+ months at level: escalate urgency.

---

**Files:** memory/achievements.json (read), career profile via `kb_get_page("career/profile")` (per profile AGENTS.md; no local Profile/AGENTS.md), memory/promotion_case.md (read/write), memory/employment_status.json (read/write), memory/salary_research.json (read)