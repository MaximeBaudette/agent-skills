---
name: online-presence
description: "Maintain Maxime's online professional presence — homepage, publications, profiles, and social channels"
version: 2.0.0
author: Andy
tags: [homepage, publications, online-presence, google-scholar, linkedin, jekyll, al-folio, website]
---

# Online Presence Management

Andy maintains Maxime's online professional presence. This covers his homepage, publication listings, and professional profiles.

## Channels

| Channel | URL / Path | Notes |
|---------|-----------|-------|
| **Homepage** | `workspace/homepage/` | Jekyll site (al-folio theme), hosted on Cloudflare Pages |
| **LinkedIn** | https://linkedin.com/in/maximebaudette | Primary professional profile |
| **Indeed** | https://profile.indeed.com/ | Secondary job-search profile |
| **GitHub** | https://github.com/MaximeBaudette | Public repos and contributions |
| **Google Scholar** | https://scholar.google.com/citations?user=Y8VOdUIAAAAJ | Publications (source of truth for bib) |

## Homepage: Site Structure

The homepage at [www.baudette.fr](https://www.baudette.fr) is an al-folio Jekyll theme site hosted on Cloudflare Pages.

| Content | Location | Format |
|---------|----------|--------|
| Publications | `_bibliography/papers.bib` | BibTeX, rendered via jekyll-scholar |
| CV data | `_data/cv.yml` | YAML, rendered via RenderCV |
| Projects | `_projects/*.md` | Markdown + frontmatter |
| Blog | `_posts/*.md` | Standard Jekyll posts |
| Config | `_config.yml` | Site-wide Jekyll config |

**Theme:** [al-folio](https://github.com/alshedivat/al-folio) — Jekyll academic theme
**Active branch:** `main` (master is retired/archived)
**Local clone:** `workspace/homepage/` (resolves to `/home/mars/.hermes/profiles/career-manager/workspace/homepage/`)
**Repo:** `github.com/MaximeBaudette/MaximeBaudette.github.io`
**Clone command (if missing):** `gh repo clone MaximeBaudette/MaximeBaudette.github.io /home/mars/.hermes/profiles/career-manager/workspace/homepage/`

## Homepage: Git Workflow

- Always `git pull --ff-only origin main` before making changes.
- Never force push.
- Commit and push only after getting Maxime's confirmation.

Git operations from within Hermes use `execute_code` with Python's `subprocess`:
```python
import subprocess
subprocess.run(["git", "pull", "--ff-only", "origin", "main"], cwd=homepage_dir)
subprocess.run(["git", "add", "-A"], cwd=homepage_dir)
subprocess.run(["git", "commit", "-m", "message"], cwd=homepage_dir)
subprocess.run(["git", "push", "origin", "main"], cwd=homepage_dir)
```

## Homepage: Publication Syncing

**Source of truth:** Google Scholar (https://scholar.google.com/citations?user=Y8VOdUIAAAAJ)
**Homepage source:** `_bibliography/papers.bib`

When asked to check or update publications, cross-reference both:
1. Extract all entries from `papers.bib`
2. Collect full publication list from Google Scholar
3. Flag entries on Google Scholar not in `papers.bib` (missing)
4. Flag entries in `papers.bib` not on Google Scholar (stale/removed)
5. Report gaps to Maxime before making changes

See `references/publication-audit.md` for the detailed step-by-step workflow.

### BibTeX Conventions
- Keys: `{firstauthor}{ShortTitle}{Year}` (e.g., `baudetteS3DK2024`)
- Follow existing file format: `= {value},` with trailing commas
- Use `{{...}}` for title casing protection
- Include `selected = {true}` for publications to feature on homepage
- Include DOI, abstract, copyright, keywords fields per existing entries
- `@misc` type for software releases (with `howpublished = {Computer software}` and `organization`)

### Entry Types by Publication Kind

| Publication Type | BibTeX Type | Key Fields |
|-----------------|-------------|------------|
| Journal article | `@article` | `journal`, `volume`, `number`, `pages` |
| Conference paper | `@inproceedings` | `booktitle` |
| Book chapter | `@book` or `@inbook` | `journal` (use for chapter in edited volume) |
| Software release | `@misc` | `howpublished = {Computer software}`, `organization` |
| Preprint | `@misc` | `howpublished = {Preprint}` |

## Homepage: Managing Projects

### Project Page Format
```yaml
---
layout: page
title: Project Name
description: One-line description
img: assets/img/image.jpg (optional)
importance: 1-5 (1 = highest)
category: work (or fun)
---
Content in markdown...
```

### Archiving Template Projects
Move template/demo projects to `_projects/archive/` so they won't render on the live site but remain accessible for reference.

## Homepage: Redesign Workflow

When Maxime asks to redesign or improve the homepage (not just content updates), follow this phased approach.

### Phase 0: Setup
- If local clone doesn't exist at `workspace/homepage/`, clone fresh via `gh repo clone`
- Confirm Cloudflare Pages auto-deploys from `main` branch

### Phase 1: Quick Content Wins (high priority, low effort)
- **Kill or archive stale blog posts** — a single old post (e.g. "Work in Progress" from 2017) actively hurts credibility. Remove or archive to `_posts/archive/`.
- **Add emoji section headers** — low effort, big visual hierarchy impact
- **Add hobbies/personality** — 1-2 sentences in the bio about what Maxime does outside work
- **Replace profile photo** — casual/lifestyle photo over standard LinkedIn-style headshot
- **Add "say hi" CTA** — invite connection (coffee, chat) based on location (Oakland/Berkeley)
- **Update CV data** — ensure experience entries reflect current work (FAST-DERMS, Grid Edge, etc.)

### Phase 2: Design Overhaul (medium priority, medium effort)

**Design direction already confirmed: Keep al-folio minimal (option D).**
Maxime confirmed on 2026-05-27: *"I want to keep my existing template... lets keep a minimal approach."* Do NOT re-open this design direction question. Focus execution on the confirmed scope below.

**Confirmed scope (color swap + content personality, no structural redesign):**
1. Custom color palette via `_sass/_variables.scss` or `_sass/_custom.scss` — warm accent (deep orange/slate), dark mode parity
2. Font refresh — clean sans headings, readable body (Google Fonts or system stack)
3. Emoji section headers across all pages
4. Content personality improvements: hobbies section, casual photo, "say hi" CTA
5. Skills section with emoji categories
6. CV data update (FAST-DERMS, Grid Edge, etc.)

**Performance baseline rule:** Before and after any visual change, check Google PageSpeed Insights (pagespeed.web.dev) for the homepage URL. Record the before/after scores. If mobile performance drops >10 points, the change is too heavy — revert or optimize. This prevents font/CDN changes from silently tanking load times.

If you encounter a situation where no design direction has been set yet (only for new builds), confirm with Maxime. Known options tested:

| Option | Description | Chosen? |
|--------|-------------|---------|
| A) Power-systems theme | Phasor motif, orange/black palette, LBNL vibes | ❌ |
| B) Terminal/CLI theme | "Grid shell" riff on Craig Breaden's aesthetic | ❌ |
| C) Clean dark-mode-first | Minimal, accent color, project-focused | ❌ |
| **D) Keep al-folio minimal** | **Color swap, custom fonts, emoji headers, personality content** | **✅ Confirmed** |

Once direction is confirmed (or loaded as pre-confirmed):
1. Custom color palette via `_sass/_variables.scss` (set accent + dark mode parity)
2. Custom hero/tagline zone for first impression
3. Skills section with categories + icons (create `_data/skills.yml` or inline on about.md)
4. Real project pages replacing template demos (FAST-DERMS, OpenIPSL, Grid Edge)
5. "Currently reading" / curiosity section
6. Footer colophon with build details + last updated date
7. Verify no al-folio version upgrade mid-project — breaks customizations

### Phase 3: Polish & Launch
- Review all pages for freshness (publications, projects, CV)
- Speed/SEO checks (image sizes, og_image, sitemap)
- Mobile + dark mode QA
- Final push to main → Cloudflare auto-deploys

## Homepage: Comparison Analysis

When the user asks for homepage improvement notes against a competitor site:

1. **Analyze target site** for design patterns, content organization, UX, technical implementation
2. **Compare with current homepage** (`workspace/homepage/`) across a feature matrix (design, content structure, UX, technical, professional presentation)
3. **Provide concise, actionable recommendations** — high-impact first, with specific file paths and implementation steps
4. **Use direct communication style** - provide recommendations without filler phrases, focusing on actionable insights

See `references/homepage-comparison-workflow.md` for the structured analysis template and `references/homepage-design-audit.md` for the baseline audit against engineeredbybreaden.com.

### External Benchmark-Driven Improvement Pattern

When analyzing external benchmarks (like Craig Breaden's engineeredbybreaden.com):
- Focus on transferable improvements, not direct copying
- Prioritize elements that enhance professional credibility and personal brand
- Document specific improvements that align with Maxime's direct communication style
- Create actionable checklists rather than vague suggestions

## Homepage: Pitfalls

- **One old blog post hurts more than none** — a stale 2017 post with no other content signals abandonment. Remove or commit to blogging.
- **Don't upgrade al-folio mid-overhaul** — theme upgrades can break SCSS overrides. Freeze the version.
- **Design direction is a Maxime decision** — don't proceed to Phase 2 without his explicit direction.
- **Humanization > credentials** — every section should answer "who is this person?" not just "what is their title?"
- **Language: English only** — never write homepage content in French unless Maxime explicitly requests it.
- **Performance baseline** — Before and after font/color/CDN changes, check PageSpeed Insights (pagespeed.web.dev). If mobile score drops >10 points, revert or optimize.
- **Competitive analysis tone** — Embed direct communication style: provide concise, actionable recommendations without filler phrases.

## REFERENCES

| File | Content |
|------|---------|
| `references/publication-audit.md` | Step-by-step workflow for auditing publications against Google Scholar |
| `references/homepage-comparison-workflow.md` | Process for analyzing competitor homepages and providing improvement recommendations |
| `references/homepage-design-audit.md` | Design critique comparing baudette.fr against engineeredbybreaden.com with 10-item improvement roadmap |
| `references/publications-2026-05-25.md` | Audit log from 2026-05-25 publication sync session (Google Scholar comparison) |
| `references/homepage-comparison-case-study-engineeredbybreaden.md` | Detailed case study analyzing Craig Breaden's homepage and transferable improvement opportunities (2026-05-27) |
