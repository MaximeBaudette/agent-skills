# Offer Letter Analysis & Contract Evaluation

**Purpose:** When Maxime receives an offer letter (typically as PDF), systematically extract terms, calculate true compensation, and compare against pipeline alternatives.

**Trigger:** Maxime shares an offer letter (PDF) — "I received the offer letter" or shares a benefits link.

---

## Phase 1: PDF Extraction

Offer letters come as PDFs from staffing agencies or directly from employers. Extract text:

```python
# Via code_execution:
import subprocess
pdf_path = "/path/to/offer-letter.pdf"
result = subprocess.run(["pdftotext", pdf_path, "-"], capture_output=True, text=True, timeout=10)
if result.returncode == 0:
    print(result.stdout)
```

**Fallback if `pdftotext` unavailable:** Try `fitz` (PyMuPDF), `pdfplumber`, or `PyPDF2` Python packages.

**Author metadata check:** Extract PDF metadata (Author, Creator, CreationDate) to verify sender identity — noted in PDF metadata fields like `/Author(name)` and `/CreationDate`.

---

## Phase 2: Key Terms Extraction

Extract these fields from the offer text:

| Field | What to look for |
|-------|-----------------|
| **Employer / Agency** | The W2 entity (e.g., Lorien/Bartech, Impellam) — not the client |
| **Client** | Where Maxime would actually work (e.g., CAISO) |
| **Job Title** | Exact title |
| **Employment Type** | Contract (W2), FTE, C2C |
| **Duration** | If contract: stated term + extension eligibility |
| **Location** | Address + hybrid/remote requirement |
| **Hourly/Salary** | The base rate |
| **PTO** | Paid? Unpaid? None? |
| **Holidays** | Paid? Unpaid? |
| **Sick Leave** | State-minimum or better |
| **Benefits Level** | Medical/dental/vision available? 401k match? |
| **Start Date** | TBD or specific |

---

## Phase 3: True Compensation Calculation

### Hourly → Annual Conversion

```
$X/hr × 40 hrs/wk × 52 wks = annual equivalent (gross)
```

### PTO/Holiday Adjustment

If no paid PTO or holidays, subtract unpaid time:

| Scenario | Deduction | Effective Annual |
|----------|-----------|-----------------|
| No unpaid time off taken | $0 | Full $178,880 |
| 2 wks vacation + 10 holidays (unpaid) | −$6,880 (2+ wks) | ~$170-172k |
| 3 wks vacation + 10 holidays (unpaid) | −$10,320 (3+ wks) | ~$168-169k |

### Benefits Gap Analysis

Quantify missing benefits as equivalent comp:

| Missing Benefit | Annual Value Estimate |
|----------------|----------------------|
| 401k match (3% typical) | $5,000-7,000 |
| Health premium subsidy (employer portion) | $3,000-8,000 |
| Paid holidays (10 days) | $3,400-6,900 |
| Paid vacation (2-3 weeks) | $6,900-10,300 |

### True Comp Formula

```
True TC = (hourly_rate × 40 × 52) − (unpaid PTO/holiday_value) − (missing_benefits_value)
```

---

## Phase 4: Pipeline Comparison

Compare against active leads side-by-side:

| Dimension | This Offer | Lead A (e.g., Intersect) | Lead B |
|-----------|-----------|-------------------------|--------|
| Employment type | Contract (W2) | FTE | ... |
| Base comp | $X/hr ($Y annual equiv) | $Z base | ... |
| Total comp (with bonus, equity) | $Y | $Z TC | ... |
| Benefits (401k, health, etc.) | Gaps noted | Full + match | ... |
| PTO | None/holidays unpaid | Paid + holidays | ... |
| Location + commute | Distance × days/wk | Remote/local | ... |
| Stability | Contract × months | FTE | ... |
| Growth potential | Limited (contract) | Career ladder | ... |

Format as a bullet-list comparison (not a table) since Telegram doesn't render tables.

---

## Phase 5: Negotiation Levers

### What You Can Move

| Lever | How | Target |
|-------|-----|--------|
| **Hourly rate** | Negotiate with agency/recruiter. Cite no benefits/PTO as justification. | $X → $X+$Y/hr |
| **Start date** | Time to keep Intersect pipeline alive | Push start 2-4 wks out |
| **Benefits clarification** | Confirm 401k match (or lack thereof), health premium coverage | Get specifics |
| **Overtime** | If contract, confirm overtime eligibility and rate | Confirm 1.5× |

### When to Push vs. When to Pass

- **Push (negotiate up)** if this is a strong backup option or you need income flow
- **Hold (accept conditionally)** if it keeps options open and doesn't conflict with better pipeline
- **Pass** if true TC falls significantly below minimum ($180k) AND better pipeline is actively moving

### The Offer Letter ≠ The Total Picture

- **Benefits links** (like `impellamna.com/benefits/associate/overview.shtml`) contain the full benefits package — 401k match, plan options, premium costs. Always extract and analyze these.
- "Level 0" benefits (common in contract agencies) indicate minimal employer-paid benefits.
- Contract agencies often have **separate enrollment portals** (Greenshades, etc.) and strict deadlines (21 days from hire).

---

## Phase 6: Maxime's Decision Support

Present options crisply:

1. **Option A: Negotiate up** — Push rate to $X/hr to offset benefits gap. Target: bring true TC to $Y+
2. **Option B: Conditional accept** — Accept as backup, keep Intersect pipeline alive
3. **Option C: Pass** — Not worth the effective comp hit + commute

Ask Maxime which direction before drafting any response.

---

## Phase 7: Registry Update

After Maxime decides:

1. Update `job_leads.json` — change status, add offer terms to notes
2. Archive the offer letter to `career/leads/YYYY-MM-company-role/`
3. If accepted: update employment status in `workspace/memory/employment_status.json`

---

## Pitfalls

- **"Annual equivalent" is misleading** for contract roles — unpaid time off, gaps between contracts, and no benefits significantly reduce true TC
- **Verify benefits links yourself** — don't trust the recruiter's summary, read the actual plan documents
- **"Level 0" benefits** mean exactly that — minimal to no employer contribution
- **Email address check:** The offer may come from the agency (not the client) — verify the domain (@bartechstaffing.com, @lorienglobal.com, @impellamna.com)
- **Metadata check:** PDF `Author` field may reveal who actually drafted the offer
- **No automatic acceptance** — per AGENTS.md, all non-digest email requires explicit Maxime confirmation. Offer acceptance is major decision, not a routine operation.

---

## See Also

- `references/post-interview-debrief.md` — capturing interview outcome and comp intel
- `career_employment-optimizer` — employment status management after acceptance
- `references/job-data-enrichment.md` — enriching lead data with comp research
