# Contract Staffing Benefits Evaluation

**Purpose:** When Maxime receives a contract offer through a staffing agency (Bartech/Lorien/Impellam, etc.), systematically evaluate the medical/dental/vision/401k plans and calculate the true cost of "Level 0" benefits.

**Context:** Contracting agencies typically offer minimal benefits (Level 0 = $0 employer contribution). Medical premiums come out of Maxime's post-tax-equivalent paycheck. No 401k match. No paid PTO/holidays. This significantly reduces effective total compensation vs. an FTE role.

---

## Phase 1: Benefits Link Extraction

The offer letter typically includes one or more benefits links. Always extract and analyze these — don't trust the recruiter's summary.

| Link Type | Example | Purpose |
|-----------|---------|---------|
| Benefits overview | `impellamna.com/benefits/associate/overview.shtml` | Plan options, enrollment portal, deadlines |
| Benefits detail | `impellamna.com/benefits/associate/associate.shtml` | Full plan summary, eligibility rules |
| Plan SBCs (PDFs) | `forms/AnthemAssociatesHDHPSummary.pdf` | Cost-sharing details, deductibles, OOP max |
| Rate sheet | See recruiter email for weekly premium rates | Actual dollar cost per pay period |

### Unknown Premium Costs

If premium costs aren't listed on the pages, check:

1. **Recruiter's email** — They often paste sample rates (e.g., Heather Stevens sent MEC rates: $42.10/wk employee)
2. **Full benefit guide** (FlipSnack or PDF) — May have rate tables
3. **Call the benefits department** (877-881-2041 for Impellam) — Rate sheet available to candidates
4. **General estimate**: If unavailable, assume $200-400/mo for employee-only HDHP, $50-150/mo for lowest-tier MEC plan

### PDF Text Extraction

Plan summaries are PDFs. Extract text via:

```python
import subprocess
pdf_path = "path/to/plan-summary.pdf"
result = subprocess.run(["pdftotext", pdf_path, "-"], capture_output=True, text=True, timeout=10)
if result.returncode == 0:
    print(result.stdout)
```

**Fallbacks (if pdftotext not available):** `fitz` (PyMuPDF), `pdfplumber`, `PyPDF2` — try each in order.

---

## Phase 2: Medical Plan Comparison

Contract agencies typically offer 2-3 plan tiers. Compare them systematically:

### Data to Extract per Plan

| Field | What to Look For | Example (Anthem HDHP) |
|-------|-----------------|----------------------|
| **Plan type** | HDHP (HSA-eligible), PPO, EPO, MEC | HDHP — HSAOAP8 |
| **Deductible (individual)** | $X,000 | $2,700 |
| **Deductible (family)** | $X,000 | $5,400 |
| **OOP max (individual)** | $X,000 | $4,350 |
| **OOP max (family)** | $X,000 | $8,550 |
| **Coinsurance** | X% after deductible | 20% in-network |
| **Preventive care** | $0 or deductible applies | $0 (not subject to deductible) |
| **HSA-eligible?** | Check IRS HDHP criteria | Yes |
| **Premium (weekly)** | $$$ per paycheck | Varies by tier |
| **Network** | PPO, POS, EPO, HMO | Open Access POS |

### Common Contract-Agency Plan Types

| Plan | Typical Use | Coverage Level | Cost |
|------|-------------|----------------|------|
| **MEC (Minimum Essential Coverage)** | Lowest-cost option | Preventative only + catastrophic. Minimal real coverage. | Lowest premium |
| **HDHP (High Deductible Health Plan)** | Moderate option | Full coverage after high deductible. HSA-eligible. | Moderate premium |
| **Essential Plan** | Higher-cost option | Lower deductible, still needs specific review | Higher premium |

### MEC Plans — Special Warning

MEC plans are **Minimum Essential Coverage** — they satisfy the ACA mandate but provide very limited actual coverage:
- Typically: preventative care only, maybe urgent care
- High out-of-pocket for anything beyond basic checkups
- NOT a real health insurance plan if you have ongoing health needs
- Premiums are lower but the value is correspondingly low

---

## Phase 3: Total Benefits Cost Calculation

### Medical Premiums

From the recruiter email or rate sheet, extract weekly/biweekly premiums:

```
Example (Impellam MEC Advantage, weekly):
  Employee only:       $42.10
  Employee + 1:        $85.52
  Employee + Family:   $125.83
```

Convert to annual: `(weekly × 52)` or `(biweekly × 26)`.

If Maxime needs employee-only coverage, that's **$42.10/wk × 52 = $2,189/yr** for the MEC plan, likely more for HDHP/Essential.

### 401k Match (or Lack Thereof)

- Most contract agencies: **NO 401k match**
- Value of a typical match: 3-6% of gross comp
- For $180k comp: **$5,400-10,800/yr foregone**
- Formula: `gross_annual × match_percent = lost_match_value`

### PTO/Holidays Gap

- Contract roles: typically zero paid PTO, zero paid holidays
- For each week of unpaid time off: `hourly_rate × 40 = lost_wage`
- For each holiday: `hourly_rate × 8 = lost_wage`
- Total: `(weeks_off × 40 × rate) + (holidays × 8 × rate)`

### Other Missing Benefits

| Benefit | Typical FTE Value | Notes |
|---------|------------------|-------|
| Health premium subsidy | $3,000-8,000/yr | Employer usually pays 75-100% of employee premium |
| Dental/Vision subsidy | $500-1,000/yr | Usually partially subsidized |
| Life/Disability insurance | $500-2,000/yr | Usually employer-paid |
| Education/training budget | $1,000-5,000/yr | Conferences, courses, certifications |

---

## Phase 4: True Compensation Formula

```
Gross annual     = hourly_rate × 40 × 52
PTO/holiday cost = (unpaid_weeks × 40 × rate) + (unpaid_holidays × 8 × rate)
Medical premium  = weekly_premium × 52
401k match loss  = gross_annual × typical_match_percent
Other gaps       = sum of missing benefits typical values (optional)

Effective TC     = Gross annual - PTO/holiday cost - Medical premium - 401k match loss
```

### Example (CAISO/Bartech offer, $90/hr assumed, 4 wks unpaid)

| Component | Value |
|-----------|-------|
| Gross annual (52 wks × 40hr × $90) | $187,200 |
| − 4 wks unpaid leave (4 × 40 × $90) | −$14,400 |
| − MEC medical premiums ($42.10 × 52) | −$2,189 |
| − 401k match loss (3% × $187,200) | −$5,616 |
| **Effective TC** | **~$165,000** |

Compare this to Maxime's stated minimum ($180k). The gap is the negotiation point.

---

## Phase 5: Rate Negotiation Target

To hit a target effective TC, solve for hourly rate:

```
Target_hourly = (Target_effective_TC + PTO_cost + Medical_cost + 401k_loss) / (40 × 52)
```

Where `401k_loss = Target_hourly × 40 × 52 × match_percent` (circular — use gross-to-net ratio from example to approximate).

**Quick rule of thumb:** For contract roles with no benefits/PTO, multiply target FTE salary by **1.25-1.35** to get equivalent hourly rate:
- $180k target → $86-93/hr
- $190k target → $91-98/hr
- $200k target → $96-108/hr

---

## Phase 6: Presenting the Gap to Maxime

Structure the recommendation as:

```
$XX/hr → $XXX,XXX gross → ~$XXX,XXX effective after [X] wks unpaid + medical + no 401k match
vs. $180k minimum → need $XX-XX/hr to close gap
```

Format as a flat list of labeled key:value pairs (Telegram doesn't render tables well):

- **Gross annual (52 wks):** $XXX,XXX
- **Effective (4 wks off, medical, no match):** ~$XXX,XXX
- **Your minimum:** $180,000
- **Rate needed to hit min:** $XX/hr

---

## Pitfalls

- **Don't trust "competitive benefits" marketing** — read the actual SBCs and rate sheets
- **MEC plans are NOT real health insurance** — they're compliance-only products. If Maxime has health needs, HDHP or Essential is the real choice, at higher premium cost
- **Premium costs are typically pre-tax** (deducted from paycheck before taxes) — this slightly reduces the effective cost vs. paying post-tax
- **HSA-eligible HDHP** can partially offset costs via pre-tax HSA contributions ($4,400 individual max for 2026) — factor this as a tax savings benefit (~20-30% effective discount on HSA-contributed amount)
- **"Level 0"** means exactly $0 employer contribution — confirm this, don't assume
- **401k may exist but with no match** — confirm both existence AND match rate, not just existence
- **State sick leave laws** — CA requires paid sick leave (1hr per 30hr worked, cap 24hr/yr for most). The offer letter said "varies by state" — CA mandate gives minimum coverage at state expense, not employer-provided benefit.
- **Enrollment window** is tight (21 days from hire) — missing it means no health insurance until open enrollment

---

## See Also

- `references/offer-letter-analysis.md` — full offer letter evaluation workflow
- `references/post-interview-debrief.md` — capturing comp intel from interviews
