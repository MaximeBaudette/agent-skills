# Mission: Market Comp Research

Survey market compensation for comparable roles. Benchmark current comp (employed) or inform target salary (job-seeking).

---

## TRIGGER

User says: "salary benchmark", "how does my comp compare", "what else is out there", "what is the market paying", or monthly cron (1st of month).

## STARTUP CHECK

1. Read memory/employment_status.json.
2. Determine mode: employed (benchmark current) or job-seeking (inform target salary from job_leads.json).
3. Read/create memory/salary_research.json.

## PROCEDURE

### Data Collection

1. Identify target role(s): from job_leads.json (job-seeking) or current role (employed).
2. Use web_search + browser for minimum 5 data points per role from:
   - levels.fyi: compensation bands by company, level, location
   - Glassdoor: salary ranges for similar roles
   - LinkedIn Salary: regional insights
   - Blind: crowd-sourced comp data
   - Job listings with salary ranges (CA/NY required disclosures)
3. Record per data point: source, url, date, company, role+level, base, bonus, equity, total comp, location.
4. Write to memory/salary_research.json under data_points.

### Gap Analysis

- Compute P25, P50, P75 for total comp.
- Compare against current (employed) or desired (job-seeking).
- Comp gap = (market_p50 - target) / target * 100.
- Flag if gap >= 15% (significant).

## OUTPUT

Write to memory/salary_research.json:
{ last_updated, mode, target_role, data_points, market_summary: {p25, p50, p75, sample_size, comp_gap}, recommendation }

Notify user: market range, gap, recommendation. If employed + gap >= 15%: "Your market value is X% above current - worth a look?"

## EDGE CASES

- Limited data (<5 points): note low confidence, still provide best estimate.
- Role too niche: search adjacent titles, broaden geography.
- Data conflicts across sources: note the range, flag discrepancies.
- Already have recent data (<30d): ask if refresh is needed.
- Gated pages (Glassdoor, Levels.fyi): use browser as fallback.

---

**Files:** memory/salary_research.json (read/write), memory/job_leads.json (read for job-seeking), memory/employment_status.json (read)