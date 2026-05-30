---
name: latex
description: "Manage and compile LaTeX projects under per-profile CORRESPONDANCE_ROOT. Projects support multiple independent entrypoints that share common files (preambles, constants, letterhead, etc.)."
version: 4.0.0
author: MARS (revamped 2026)
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [latex, documents, correspondance, pdf, tectonic]
---

# LaTeX Document Production

This skill lets agents create and compile professional LaTeX documents while respecting per-profile isolation via `CORRESPONDANCE_ROOT`.

## Core Model

- Every profile has its own `CORRESPONDANCE_ROOT` (see Setup below).
- A **project** is a folder inside the correspondance root.
- Projects are designed from the start to support **multiple compilable documents** (entrypoints) that can share common files.
- Common / shared files go in `common/` by convention (documented per correspondance root — see AGENTS.md guidance).
- Entry points are listed in `latex-project.json`.

This structure works well for:
- Single letters or CVs
- Packages with several related documents (e.g. USCIS submissions with cover letter + multiple supporting letters)
- Projects that evolve over time by adding new entrypoints

## Setup — CORRESPONDANCE_ROOT

Each profile must declare its own root. Add it to the profile's `.env` (recommended) or clearly document it in the profile's AGENTS.md.

**Standard values:**

```bash
# Andy
CORRESPONDANCE_ROOT=/home/mars/.hermes/profiles/career-manager/workspace/correspondance

# Cooper
CORRESPONDANCE_ROOT=/home/mars/.hermes/profiles/health-coach/workspace/correspondance

# MARS
CORRESPONDANCE_ROOT=/home/mars/.hermes/workspace/correspondance
```

Create the directory if it doesn't exist:

```bash
mkdir -p "$CORRESPONDANCE_ROOT"
```

Restart the gateway or start a fresh session after setting the variable.

**Important:** Inside each `CORRESPONDANCE_ROOT`, create an `AGENTS.md` file (or similar) that documents local conventions for that profile's correspondance work. This is where you explain the `common/` pattern, naming preferences, etc.

## Project Structure (Multi-Entrypoint by Default)

A typical project looks like this:

```
<project-name>/
├── latex-project.json
├── common/                    # Shared files (preambles, constants, letterhead, macros, etc.)
│   ├── constants.tex
│   └── letterhead.tex
├── cover-letter.tex           # Entrypoint
├── letter-of-intent.tex       # Entrypoint
├── expedite-request.tex       # Entrypoint
├── .gitignore
└── output/
    ├── cover-letter.pdf
    ├── letter-of-intent.pdf
    └── expedite-request.pdf
```

### latex-project.json

```json
{
  "name": "2026-05-USCIS-AOS",
  "entrypoints": [
    { "file": "cover-letter.tex", "label": "Cover Letter" },
    { "file": "letter-of-intent.tex", "label": "Letter of Intent" },
    { "file": "expedite-request.tex", "label": "Expedite Request" }
  ],
  "upload": {
    "gdrive_folder_id": null,
    "email": null
  }
}
```

- `entrypoints` lists every document that should produce its own PDF.
- The skill and scripts use this list to know what can be compiled.

## Creating a New Project

Use the convenience script (recommended for consistency):

```bash
bash ~/.hermes/skills/latex/scripts/new-project.sh "2026-05-motivation-letter-acme"
```

This creates a project already structured for multiple entrypoints + a `common/` directory.

You can also create the structure manually following the layout above.

## Compiling

### Recommended: Use the compile script

From inside the project directory or by passing the full path:

```bash
# Compile EVERY entrypoint listed in latex-project.json
bash ~/.hermes/skills/latex/scripts/compile.sh /path/to/project

# Compile only one specific document
bash ~/.hermes/skills/latex/scripts/compile.sh /path/to/project cover-letter.tex
```

The script will:
- Compile the requested entrypoint(s)
- Place PDFs in `output/` named after the `.tex` file (e.g. `cover-letter.pdf`)
- Respect the project root so `\input` and `\include` resolve correctly

### Direct tectonic usage (robust & transparent)

You can (and often should) compile directly:

```bash
cd "$CORRESPONDANCE_ROOT/my-project"
mkdir -p output

# Compile one document
tectonic --outdir output cover-letter.tex

# Compile another
tectonic --outdir output letter-of-intent.tex
```

This is the most reliable method. The scripts are conveniences on top of this.

**Always run tectonic from the project root.**

## Discovering Entry points

When working on an existing project:
1. Read `latex-project.json`
2. Look at the `entrypoints` array — these are the documents you can (and usually should) compile separately.

The skill instructions should make agents check this file first when asked to compile or update documents in a project.

## Shared Files Convention (`common/`)

Place files that are meant to be `\input` or `\include` (but never compiled alone) in a `common/` directory at the project root.

Example usage in an entrypoint:

```latex
\input{common/constants}
\input{common/letterhead}
```

**This is a recommended convention**, not enforced by the compiler. Document the exact pattern used in a given correspondance root inside an `AGENTS.md` file at the root of that profile's `CORRESPONDANCE_ROOT`. This gives flexibility across different projects and profiles.

## Upload & Delivery

After successful compilation, PDFs live in `output/`.

Use the `google-workspace` skill for:
- Uploading specific PDFs to Drive
- Sending them by email

The `latex-project.json` still supports the `upload` section for optional automation hints.

## Installing Tectonic

```bash
curl --proto '=https' --tlsv1.2 -LsSf \
  https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.15.0/tectonic-x86_64-unknown-linux-musl.tar.gz \
  | tar xz -C ~/bin
```

Ensure `~/bin` is in PATH for the relevant profiles.

## Best Practices

- Default to multi-entrypoint projects from the beginning (easier to grow).
- Keep shared logic in `common/`.
- Name entrypoint files clearly (they determine the PDF names).
- Always compile from the project root.
- Use the scripts for scaffolding and bulk work; fall back to direct `tectonic` when you need precision or debugging.
- Document profile-specific conventions in an `AGENTS.md` at the correspondance root level.

## Notes

- Output is always git-ignored (`output/` in `.gitignore`).
- The skill is intentionally a mix of clear conventions + helpful scripts on top of the excellent direct `tectonic` experience.

This model supports both simple single documents and complex multi-document packages while keeping everything isolated per profile.

## Shared Templates & Examples

A ready-to-use multi-document example lives here:

`skills/latex/templates/example-multi-document/`

It contains two entrypoints (`cover-letter.tex` and `motivation-letter.tex`) that share files from `common/`.

Copy the folder into a real `CORRESPONDANCE_ROOT`, rename it, and start editing. This is the recommended starting point for most new projects.