# Publication Audit Workflow

Cross-reference homepage publications (`_bibliography/papers.bib`) against Google Scholar.

## Steps

1. **Read current BibTeX:**
   - Open `workspace/homepage/_bibliography/papers.bib`
   - Extract all `@entry{key,` entries and their years

2. **Fetch Google Scholar publications:**
   - URL: https://scholar.google.com/citations?user=Y8VOdUIAAAAJ&hl=en&sortby=pubdate&pagesize=100
   - Extract all listed publications with titles, authors, year, venue

3. **Compare:**
   - Match entries by title (fuzzy — Google Scholar titles may differ slightly from BibTeX)
   - Note any Google Scholar entries not found in `papers.bib` → **MISSING**
   - Note any `papers.bib` entries not on Google Scholar → **STALE/REMOVED**

4. **Report gaps to Maxime** in a table:
   ```
   | Year | Title | Venue | Status |
   |------|-------|-------|--------|
   | 2025 | FRS-FASTDERMS v0.9 | LBNL | MISSING |
   ```

5. **Editing `papers.bib`:** Default rule is to present the diff and wait for confirmation. However, if Maxime explicitly says "go ahead" / "update my homepage" / "yeah go ahead update" then proceed to edit directly without re-asking.

## BibTeX Entry Standards

Follow the existing convention in `papers.bib`:
- Title casing protected with `{{double braces}}`
- `author = {Last, F. and Last2, F.},` format with initials
- `doi = {10.xxx/xxxxx},` always included when available
- `abstract = {...}` — concise 2-4 sentence summary
- `copyright = {All rights reserved},` on all entries
- `keywords = {word1,word2,...},` for categorization
- `selected = {true},` for featured papers (appear on homepage)
- Entry key format: `{firstauthor}{CamelCaseTitle}{year}`

## Entry Types by Publication Kind

| Publication Type | BibTeX Type | Key Fields |
|-----------------|-------------|------------|
| Journal article | `@article` | `journal`, `volume`, `number`, `pages` |
| Conference paper | `@inproceedings` | `booktitle` |
| Book chapter | `@book` or `@inbook` | `journal` (use for chapter in edited volume) |
| Software release | `@misc` | `howpublished = {Computer software}`, `organization` |
| Preprint | `@misc` | `howpublished = {Preprint}` |

## Common Missing Publications

Recent work (2023-2025) is most likely missing — Maxime's LBNL/NREL projects post-2021:
- FAST-DERMS-related publications (2022-2025, NREL collaborators)
- S3DK toolkit (2024) and follow-up works
- FRS-FASTDERMS software release (2025, DOE registered)
- Federated controls papers (Grid Edge 2025)
- Load forecasting with EV papers (NAPS 2024)
- Book chapters may have multiple editions (2014, 2017)
