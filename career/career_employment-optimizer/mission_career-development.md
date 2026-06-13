# Mission: Career Development

Long-term career pathing — identify skill gaps, build development plans, track learning, advise on strategic moves. Adapts for job-seeking context when unemployed.

---

## TRIGGER

User says: "what are my skill gaps", "career development plan", "where should I grow", or promotion stall (18+ months same level).

## STARTUP CHECK

1. Read memory/employment_status.json. If unemployed -> focus on skill-building for job search.
2. Read the owned career profile via `kb_get_page("career/profile")` (per the profile AGENTS.md instructions) for career goals, target roles, learning priorities.
3. Read memory/career_development_plan.md (existing plan/progress).

## PROCEDURE

### 1. Skill Gap Analysis

- Define target role: from owned Prime Radiant profile (`kb_get_page("career/profile")`) or ask "Where do you see yourself in 2-3 years?"
- Research target requirements: use web_search + browser for job descriptions, required skills, certifications, emerging trends.
- Build gap matrix: Skill | Required Level | Current Level | Gap | How to Close | Timeline
- Rate current: None/Beginner/Intermediate/Advanced/Expert. Rate gap: Critical/Important/Nice-to-have.

### 2. Development Plan

- Prioritize critical gaps first, then important gaps aligned with interests.
- For each gap: learning resources (courses, books), practice projects, mentorship, timeline, evidence goal.
- Write to memory/career_development_plan.md:
  ## Target Role: [Role], [Level]
  ## Priority Gaps
  ### [Skill] - Critical/Important
  Current: [level] -> Target: [level]. Path: [resources + practice]. Evidence: [proof]. Timeline: [milestones]

### 3. Progress Tracking

- Monthly: ask about active goals, update milestones.
- Quarterly: reflect on skills gained, new gaps, adjust plan.

### 4. Strategic Advice

When user asks "stay or go" or "what to focus on", assess 4 dimensions (0-10):

| Dimension | Explore |
|---|---|
| Growth | Learning? Path to next level? Skills appreciating? |
| Compensation | Market-aligned? Trajectory? (use salary_research.json) |
| Satisfaction | Enjoy work? Energized or drained? |
| Stability | Company health? Team stable? Role secure? |

Growth <5 AND Satisfaction <5 -> serious exploration (cross-invoke career_job-seeking). Comp <5 -> run Market Comp Research first. All >7 -> double down.

### 5. Long-Term Pathing

5-year vision exercise (annual/on request): define vision, work backwards year by year, identify next concrete step. Present 2-3 trajectories: conservative (current track), ambitious (stretch role), pivot (new industry/function).

## OUTPUT

- Gap matrix and plan written to memory/career_development_plan.md
- Progress updates (monthly) and quarterly reflections
- Strategic advice on request

## EDGE CASES

- No target role defined: ask before proceeding with analysis.
- Owned profile in Prime Radiant stale: use `kb_get_page("career/profile")` + ask user to confirm goals / target roles before gap analysis.
- Learning plan too ambitious: suggest top 2-3 priorities with realistic timelines.
- User in pivot mode: focus on transferable skills and adjacent-role research.
- Already at career ceiling: surface differentiator skills and network-building strategies.

---

**Files:** memory/career_development_plan.md (read/write), career profile via `kb_get_page("career/profile")` (per profile AGENTS.md; no local Profile/AGENTS.md), memory/achievements.json (read), memory/salary_research.json (read), memory/employment_status.json (read)