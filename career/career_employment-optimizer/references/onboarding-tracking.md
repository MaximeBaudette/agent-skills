# Onboarding Tracking After Offer Acceptance

**Trigger:** Any lead reaches `status: "accepted"` or `status: "offer_accepted"`.

**Gap identified:** The job-leads → accepted → employed transition has no automated tracking of onboarding details.

## Required Data to Collect

After Maxime confirms acceptance, document these items:

| Item | Where to Store | Example |
|------|---------------|---------|
| Start date | `employment_status.json`, lead notes | 2026-06-15 |
| Reporting manager | Lead notes | Yu Wan (rthordarson@caiso.com) |
| Hourly/salary rate | Registry notes + `salary_range` | $88/hr |
| Equipment status | Lead notes | Laptop shipped? Badge issued? |
| Onboarding paperwork | Lead notes | I-9, W-4, NDA signed? |
| First day logistics | Lead notes | Where to go, who to meet, time |
| Benefits enrollment | Lead notes | Bartech opt-in by when? |
| Background check | Lead notes | Completed? Pending? |

## Acceptance → Onboarding Checklist

1. **Day of acceptance** — record `accepted_date`, rate, and key contacts in BOTH `job_leads.json` and `job_registry.json`
2. **+2 days** — if no start date documented, flag for follow-up ("Start date not confirmed yet")
3. **+7 days** — if no start date AND no onboarding activity, escalate ("No onboarding progress — may need to chase recruiter")
4. **First day** — log `employment_status.json` → `status: "employed"`, `start_date`, `role`, `manager`
5. **+30 days** — shift from job-seeking to employment-optimizer mode (achievement tracking, quarterly review prep)

## Employment Status File Update

```json
{
  "status": "employed",
  "role": "Power Systems Engineer",
  "company": "CAISO (via Bartech Staffing)",
  "start_date": "2026-06-15",
  "end_date": null,
  "compensation": {
    "rate": "$88/hr",
    "type": "contract W2",
    "overtime_eligible": true,
    "estimated_annual": "$164,736 (no OT) / ~$196k (with 5hr/wk OT)"
  },
  "manager": {
    "name": "Yu Wan",
    "contact": "rthordarson@caiso.com"
  }
}
```

## Onboarding Tracker (Suggested Structure)

When onboarding activity is ongoing, keep a running log in the lead notes:

```
[2026-06-04] Background check initiated — Sterling background check link sent
[2026-06-05] I-9 completed via Bartech portal
[2026-06-07] Start date confirmed: June 15
[2026-06-08] Laptop received — Dell Precision, FedEx
[2026-06-10] Badge access set up — Folsom office, building 3
[2026-06-15] FIRST DAY
```

## Relationship to Other Skills

- Once employed, the `career_employment-optimizer` startup gate should show `Employed` state
- Achievement tracking begins Day 1
- Contract end date (12 months) should auto-trigger a career_job-seeking pre-emptive reminder at month 10
