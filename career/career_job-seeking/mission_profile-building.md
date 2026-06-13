# Mission: Profile Building

**Trigger:** "build profile" | "refresh profile" | "update my profile"

**Parameters:** mode = headless | interactive (default: interactive if not specified)

**Startup Check:**
None. No feedback dependency (profile is source data, not execution feedback).

**Procedure:**
1. Phase 1 (Gather): Read current owned profile via `kb_get_page("career/profile")` (Prime Radiant). Search web for name + Google Scholar (papers), GitHub projects, personal website. Extract: roles, skills, seniority, timeline, research, notable projects.
2. Phase 2a (Headless): Synthesize into Standard Profile Architecture. Update the owned page via `authoritative_push` (knowledge-base skill helper) on slug "career/profile" (author "andy"). Report completion via message with summary.
3. Phase 2b (Interactive): Present summary to Maxime. Ask 5-10 follow-up questions (gaps, target adjustments, salary floor, deal-breakers). Wait for answers.
4. Phase 3 (Interactive Finalize): Update draft with answers. authoritative_push the final to "career/profile". Confirm completion.

**Standard Profile Architecture:**
```
markdown
# [Name] - [Primary Title]
## Target Roles
## Seniority
## Key Skills & Technical Competencies
## Location Tiers & Relocation
## Salary & Compensation
## Deal-breakers
## Target Companies
## Academic & Research Contributions
## Notable Projects & Portfolio
```

**Output:** Updated owned profile page in Prime Radiant via authoritative_push (nearly verbatim + light encyclopedist polish). The KB page is the source of truth; no local CV/workspace master or symlink.

**Edge Cases:**
- CV not found -> proceed with memory/knowledge and web search; note gaps for interactive mode.
- No web footprint (papers, GitHub) -> skip, note gaps.
- Mode not specified -> default to interactive (safest; gathers feedback before writing).
- Profile write fails -> alert Maxime with synthesized content as fallback.
