# AGENTS.md — Correspondance Root Conventions

This file lives at the root of a profile's `CORRESPONDANCE_ROOT` (e.g. inside `~/.hermes/profiles/career-manager/workspace/correspondance/AGENTS.md`).

It documents local conventions for LaTeX work in this profile so all agents stay consistent.

## Project Structure

Every project should follow this layout:

```
<project-name>/
├── latex-project.json
├── common/                    # Shared files meant to be \input / \include
│   ├── constants.tex
│   ├── letterhead.tex
│   └── formatting.tex
├── *.tex                      # Entry points (documents that produce PDFs)
├── .gitignore
└── output/                    # Compiled PDFs (gitignored)
```

## Shared Files (`common/`)

- Put any file that is **not** a standalone document in `common/`.
- Typical contents: constants, letterhead, macros, shared formatting, signatures, etc.
- These files are included via `\input{common/xxx}` or `\include{common/xxx}` from the entrypoints.
- Do **not** compile files inside `common/` directly.

Example in an entrypoint:

```latex
\input{common/constants}
\input{common/letterhead}

\begin{document}
...
\end{document}
```

## Entry points

- Listed in `latex-project.json` under the `entrypoints` array.
- Each entrypoint produces its own PDF.
- PDF names are derived directly from the `.tex` filename (e.g. `cover-letter.tex` → `cover-letter.pdf`).
- When asked to compile or update documents, first read `latex-project.json` to discover all available entrypoints.

## Compilation

Preferred commands (from project root):

```bash
# Compile all entrypoints in the project
bash ~/.hermes/skills/latex/scripts/compile.sh .

# Compile only one specific document
bash ~/.hermes/skills/latex/scripts/compile.sh . cover-letter.tex
```

Direct tectonic is also fully supported and often preferred for precision:

```bash
cd /path/to/project
tectonic --outdir output cover-letter.tex
```

## Naming & Organization

- Use clear, descriptive project folder names (e.g. `2026-05-USCIS-AOS`, `motivation-letter-acme-2026`).
- Keep related documents that share content in the **same project** rather than splitting them.
- One project = one logical package of documents.

## Git Hygiene

- `output/` must always be gitignored.
- The `new-project.sh` script automatically creates a `.gitignore` with `output/`.

## Profile-Specific Notes

(Add any extra rules that apply only to this profile below)

---

**Last updated:** YYYY-MM-DD
**Maintained by:** [Profile owner or MARS]