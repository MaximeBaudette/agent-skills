# Mission: Achievement Tracker

Log professional wins in STAR format. Maintain a running achievements.json for Quarterly Review and Promotion Strategy. Proactive bi-weekly nudge.

---

## TRIGGER

User says: "log achievement", "I shipped X", "log this win", or First Monday with no entry in 21 days.

## STARTUP CHECK

1. Read memory/employment_status.json. If unemployed -> STOP (handled by SKILL gate).
2. Note current company, role, start date.

## PROCEDURE

### Log an Achievement

1. Ask conversationally: what happened? (1-sentence summary), situation/problem, your actions, measurable result, date (month/year), impact level (individual/team/org/industry).
2. Format as STAR:
   ```
   SITUATION: <context/problem>
   TASK: <what needed to be done>
   ACTION: <what you did, skills used>
   RESULT: <measurable outcome>
   ```
3. Append to memory/achievements.json:
   {
     "id": "ach-YYYYMMDD-NNN", "date": "YYYY-MM-DD",
     "title": "<summary>",
     "star": {"situation": "...", "task": "...", "action": "...", "result": "..."},
     "impact_level": "individual|team|org|industry",
     "skills_demoed": [...],
     "metrics": "...", "quarter": "Q1|Q2|Q3|Q4", "year": 2026
   }
4. Confirm: "Logged: [title]. Impact: [level]. Achievement #N this quarter."
5. If no metrics: gently ask for numbers. If org/industry impact: flag as promotion-case material.

### Proactive Nudge (Bi-weekly)

1. Check achievements.json for entries in last 21 days.
2. 0 entries -> nudge. 1-2 -> acknowledge + ask for more. 3+ -> acknowledge.
3. Offer to refine metrics/impact on recent entries.

### Quarterly Summary (for Qtrly Review mission)

Provide: count per quarter, sorted by impact (org>team>individual), skills demonstrated, themes. Write to memory/promotion_case.md under ## Q[N] Achievement Summary.

## OUTPUT

- Achievement appended to memory/achievements.json
- Summary written to memory/promotion_case.md (if quarterly)
- Confirmation sent to user

## EDGE CASES

- Rough notes: Extract what you can, fill gaps conversationally.
- Achievement mentions promotion/promoted -> flag for Promotion Strategy.
- Achievement mentions raise/salary/comp -> route to Promotion Strategy §5.
- Org/industry impact: highlight for quarterly review.
- Quarter ending < 2 weeks with < 3 achievements -> flag for brainstorming.

---

**Files:** memory/achievements.json (append), memory/promotion_case.md (write), memory/employment_status.json (read)