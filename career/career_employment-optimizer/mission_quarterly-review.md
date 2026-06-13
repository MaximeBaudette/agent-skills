# Mission: Quarterly Review Prep

Compile achievements into a structured self-assessment narrative. Produce review-ready talking points.

---

## TRIGGER

User says: "compile my achievements", "prep for review", "what did I accomplish", or quarter end within 3 weeks.

## STARTUP CHECK

1. Read memory/employment_status.json. If unemployed -> STOP.
2. Confirm current quarter (Q1=Jan-Mar, etc.).
3. Read the owned career profile via `kb_get_page("career/profile")` (per the profile AGENTS.md instructions) for role, level expectations, goals.

## PROCEDURE

### 1. Gather Achievements

- Read memory/achievements.json, filter to current quarter.
- Read memory/promotion_case.md for prior summaries.
- If < 2 entries: alert and brainstorm before proceeding.
- Categorize by impact: Tier 1 (org/industry), Tier 2 (team), Tier 3 (individual).
- Map to competencies: Technical Excellence, Leadership & Collaboration, Innovation & Impact, Execution & Reliability.

### 2. Build Narrative

Write to memory/promotion_case.md under ## Q[N] [Year] Review Narrative:

```
## Q[N] [Year] Self-Assessment

### Overview (2-3 sentences: quarter theme, headline result)

### Key Achievements
#### [Title] - [Impact Level]
Context: [Situation + Task]
What I did: [Action, active voice]
Impact: [Result, quantified]
Competency alignment: [review criteria]

### Areas of Growth (1-2, framed positively)
### Goals for Next Quarter (2-3 specific, measurable)
```

For each: note PRs/project names/metrics. Suggest self-rating per competency (Exceeds/Meets/Developing).

### 3. Deliver & Talking Points

- Send narrative as Telegram markdown.
- Ask: adjust framing? Missing wins? Prep talking points?
- If yes: generate 5-7 talking points (opening 30s, top 3 highlights 60s each, growth 30s, goals 30s, ask 30s).

## OUTPUT

- Narrative appended to memory/promotion_case.md
- Telegram message to Maxime
- Talking points (on request)

## EDGE CASES

- Empty quarter: fewer than 2 entries -> brainstorm before proceeding.
- Cross-quarter wins: ask if prior-quarter achievements should be included.
- No review cycle known: ask when review is scheduled.
- User is unhappy with narrative: offer to reframe specific sections.

---

**Files:** memory/achievements.json (read), memory/promotion_case.md (write), career profile via `kb_get_page("career/profile")` (per profile AGENTS.md; no local Profile/AGENTS.md), memory/employment_status.json (read)