---
name: latex
description: "Create and compile LaTeX documents. Supports both organized projects under a CORRESPONDANCE_ROOT (recommended for remote agents) and ad-hoc projects located anywhere on disk (common on personal development machines)."
version: 4.0.0
author: MARS (revamped 2026)
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [latex, documents, correspondance, pdf, tectonic]
---

# LaTeX Document Production

This skill helps agents create and compile LaTeX documents.

It is designed to work well in two different environments:

- **On remote agents** (MARS, Andy, Cooper): Use the structured `CORRESPONDANCE_ROOT` model for organized, centralized document work.
- **On personal development machines** (like this one): Work with LaTeX projects that live anywhere on disk. The structured root is optional.

## Core Model

The skill supports two main ways of working:

### Organized Mode (Recommended for remote agents)
- Use a dedicated `CORRESPONDANCE_ROOT` per profile.
- All serious correspondance work lives under this root.
- Projects inside it can contain multiple entrypoints that share files from a `common/` directory.

### Ad-hoc / Development Mode (Common on personal machines)
- Projects can live anywhere on the filesystem.
- You can still use `latex-project.json` + multiple entrypoints + a `common/` folder inside any project.
- No central root is required.

In both modes, projects can support **multiple compilable documents** (entrypoints) that share common files (preambles, constants, letterhead, etc.).

Entry points are declared in `latex-project.json`.

This structure works well for:
- Single letters or CVs
- Packages with several related documents (e.g. USCIS submissions with cover letter + multiple supporting letters)
- Projects that evolve over time by adding new entrypoints

## Setup

### 1. (Optional but recommended) Declare CORRESPONDANCE_ROOT

On remote agents (MARS, Andy, Cooper), it is strongly recommended to have a dedicated `CORRESPONDANCE_ROOT` per profile for organized document work.

On personal development machines, you can skip this entirely and work with projects located anywhere. The rest of the skill still works.

If you do want to use a central root, add it to the profile's `.env` (recommended) or document it in the profile's AGENTS.md.

**Standard values** (only needed if you decide to use a central root):

```bash
# Andy
CORRESPONDANCE_ROOT=/home/mars/.hermes/profiles/career-manager/workspace/correspondance

# Cooper
CORRESPONDANCE_ROOT=/home/mars/.hermes/profiles/health-coach/workspace/correspondance

# MARS
CORRESPONDANCE_ROOT=/home/mars/.hermes/workspace/correspondance
```

If you set one, create the directory:

```bash
mkdir -p "$CORRESPONDANCE_ROOT"
```

Then restart the gateway or start a fresh session.

**Tip for this machine:** Since you have LaTeX projects scattered across many locations, you probably don't need (and shouldn't force) a single `CORRESPONDANCE_ROOT` here. The structured root model is mainly useful on the remote agents.

### 2. Fetch Supporting Scripts (for full functionality)

`hermes skills install` only pulls the core `SKILL.md`. The scripts that provide convenient scaffolding are **not** installed automatically.

To get the full experience (`new-project.sh` and `compile.sh`), run these commands once per profile:

```bash
mkdir -p "$CORRESPONDANCE_ROOT/.scripts"
curl -fsSL https://raw.githubusercontent.com/MaximeBaudette/agent-skills/main/skills/latex/scripts/new-project.sh \
  -o "$CORRESPONDANCE_ROOT/.scripts/new-project.sh"
curl -fsSL https://raw.githubusercontent.com/MaximeBaudette/agent-skills/main/skills/latex/scripts/compile.sh \
  -o "$CORRESPONDANCE_ROOT/.scripts/compile.sh"
curl -fsSL https://raw.githubusercontent.com/MaximeBaudette/agent-skills/main/skills/latex/scripts/setup.sh \
  -o "$CORRESPONDANCE_ROOT/.scripts/setup.sh"

chmod +x "$CORRESPONDANCE_ROOT/.scripts/"*.sh
```

You can then run them as:
```bash
bash "$CORRESPONDANCE_ROOT/.scripts/new-project.sh" "my-project"
bash "$CORRESPONDANCE_ROOT/.scripts/compile.sh" "$CORRESPONDANCE_ROOT/my-project"
```

Alternatively, copy the scripts directly from the installed skill if you have them:
```bash
cp -r ~/.hermes/skills/latex/scripts/ "$CORRESPONDANCE_ROOT/.scripts/"
```

### 3. Install Tectonic (one time per host)

```bash
curl --proto '=https' --tlsv1.2 -LsSf \
  https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.15.0/tectonic-x86_64-unknown-linux-musl.tar.gz \
  | tar xz -C ~/bin
```

Make sure `~/bin` is in PATH for the relevant profiles.

## Quick Start — Compile a Single File (No Scripts Needed)

If you just have a folder with one `.tex` file and want to compile it quickly:

```bash
cd /path/to/some-folder-with-latex
mkdir -p output

# One command — no scripts required
tectonic --outdir output main.tex
```

The resulting PDF will be at `output/main.pdf`.

This is the simplest possible path and works even if you have never set up `CORRESPONDANCE_ROOT` or fetched any scripts.

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

You can create a new project anywhere (no need for `CORRESPONDANCE_ROOT`).

Use the convenience script:

```bash
bash ~/.hermes/skills/latex/scripts/new-project.sh "2026-05-motivation-letter-acme" /path/to/parent/folder
```

Or simply run it from inside the directory where you want the project:

```bash
cd /some/arbitrary/location
bash ~/.hermes/skills/latex/scripts/new-project.sh "my-project"
```

This creates a project already structured for multiple entrypoints + a `common/` directory.

You can also create the structure manually.

## Compiling

For the absolute simplest case (one file, no project structure), see **Quick Start — Compile a Single File** above.

### Recommended: Use the compile script (for proper projects)

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

## Best Practices

- On personal machines, feel free to keep LaTeX projects wherever they naturally live. The skill works fine without a central root.
- On remote agents, use `CORRESPONDANCE_ROOT` for better organization.
- Default to multi-entrypoint projects when documents share content (easier to grow).
- Keep shared logic in a `common/` folder inside the project.
- Name entrypoint files clearly (they determine the PDF output names).
- Always run Tectonic from inside the project directory.
- Use the scripts for convenience, but direct `tectonic` commands are perfectly valid and often simpler.
- If you do use a `CORRESPONDANCE_ROOT`, document local conventions in an `AGENTS.md` inside it.

## Notes

- Output is always git-ignored (`output/` in `.gitignore`).
- The skill is intentionally a mix of clear conventions + helpful scripts on top of the excellent direct `tectonic` experience.

This model supports both simple single documents and complex multi-document packages while keeping everything isolated per profile.

## Shared Templates & Examples

A ready-to-use multi-document example lives here:

`skills/latex/templates/example-multi-document/`

It contains two entrypoints (`cover-letter.tex` and `motivation-letter.tex`) that share files from `common/`.

Copy the folder into any location (inside a `CORRESPONDANCE_ROOT` or anywhere else), rename it, and start editing. This is a good starting point for both organized and ad-hoc projects.