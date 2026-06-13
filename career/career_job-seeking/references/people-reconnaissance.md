# People & Team Reconnaissance

**Purpose:** When a referral or conversation identifies specific people at a target company, systematically research their backgrounds, the team structure, and how to position yourself relative to them.

**Trigger:** You learn names of team members at a target company (e.g., "Tonya mentioned Craig and Ed are on the microgrid team").

---

## Methodology

### Phase 1: Name + Context Inventory

Start with what you know:

| Person | Source | Known Context | Relationship |
|--------|--------|---------------|-------------|
| Craig Breaden | Tonya | Worked together 2018 at LBL when he was at SGS | Co-author on paper |
| Ed (McCullough?) | Tonya | Team manager | Unknown |

Fix missing last names first — "Ed" → web search `"Ed" "Intersect" microgrid manager` to confirm surname.

### Phase 2: Multi-Source Parallel Scrape

For each person, search across these sources simultaneously:

1. **Web search** — `"Full Name" "Company" role/keyword` (catches LinkedIn previews, press releases, job postings mentioning them)
2. **Personal website** — Often has fuller bio than LinkedIn. Look for: `engineeredby<name>.com`, `<name>.com`, GitHub profile
3. **ResearchGate / Google Scholar / IEEE** — Publications reveal co-authors, research areas, and crucially: **any prior connection to you** (co-authored papers, same lab, same projects)
4. **Company about/team page** — Look for bios, headshots, team hierarchy
5. **Active job postings** — Critical for inferring team structure. Roles being hired = gaps in current team. Extract titles, focus areas, locations, comp ranges.

### Phase 3: Cross-Reference + Connect

- **Publication overlap:** If you co-authored with them, pull the paper. It's a verifiable shared history you can reference naturally.
- **Institutional overlap:** Same prior company? Same university? Same project?
- **Timeline check:** When did they leave a shared prior employer? Was it before/after your overlap?

### Phase 4: Team Structure Inference

From job postings, piece together the org chart:

```
Head of Microgrids (Ed McCullough)
├── Microgrid Controls (Craig Breaden) — controls software
├── [hiring] Software Engineer, Microgrid Controls Developer — real-time control code
├── [hiring] Software Engineer, Microgrid Controls Validation Engineer — SIL/HIL
├── [hiring] Power Systems Engineer, Microgrids — EMT modeling, PSCAD
├── [hiring] Microgrid Protections Engineer — relay settings, IEC 61850
└── [hiring] Sr. Control Systems Engineer — plant architecture (15+ yrs)
```

Patterns to note:
- Hires across hubs (SF, NYC, Houston, Denver, Austin, Calgary, Toronto) → distributed team
- Comp bands cluster → tells you seniority level being hired
- "Validation Engineer" + "Protections Engineer" as separate roles → serious about rigor

### Phase 5: Profile Synthesis

For each person, deliver:

| Field | Content |
|-------|---------|
| **Role** | Title at company |
| **Location** | City/country |
| **Education** | Degree, school, year |
| **Prior experience** | Key roles and companies |
| **Shared history** | How you're connected (co-author, past project, same lab) |
| **Skill stack** | Technical areas evident from bio/publications |
| **What to note** | Things to mention or ask in interviews |

---

## Output Format

Lead with a **team landscape** (org chart or table), then individual profiles. End with **strategic context** (company scale, what the team is building, implications for your positioning).

---

## Pitfalls

- **LinkedIn truncation:** Public previews are limited. Use web search snippets and other sources to fill gaps.
- **Same-name collision:** Filter by university, industry, and company to disambiguate (e.g., there are multiple Craig Breadens — the archivist is a different person).
- **Stale job postings:** Roles may already be filled. Cross-check posting dates and status.
- **Acquisition context:** Company ownership changes everything about positioning. Always check recent acquisition history (see `references/intersect-company-intelligence.md`).
- **Don't fabricate history:** If you only briefly worked together 7 years ago, say that. Don't inflate to "long-time collaborator."

---

## See Also

- `references/intersect-company-intelligence.md` — company-level positioning
- `references/lead-directory-convention.md` — where to store per-lead docs
