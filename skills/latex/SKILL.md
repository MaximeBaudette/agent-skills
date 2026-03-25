---
name: latex
description: Compile LaTeX documents using the Tectonic engine. Use this skill whenever the user wants to create, edit, or compile a LaTeX document — letters, articles, CVs, reports. Tectonic is a self-contained compiler that auto-downloads only the packages it needs.
metadata:
  { "openclaw": { "emoji": "📄", "os": ["linux", "darwin"], "requires": { "bins": ["tectonic"] } } }
---

# LaTeX Skill (via Tectonic)

Compile LaTeX documents locally using [Tectonic](https://tectonic-typesetting.github.io/) — a single binary that auto-downloads only the packages your document needs.

## Workspace Layout

All LaTeX projects live under `~/.openclaw/agent_mars/correspondance/`:

```
~/.openclaw/agent_mars/correspondance/
├── templates/              ← (optional) shared templates — see Templates section
└── <project-name>/
    ├── latex-project.json  ← project config (entrypoints, upload targets)
    ├── main.tex            ← your source (multi-file via \input is supported)
    └── output/
        └── main.pdf        ← compiled output (gitignored)
```

## Per-Project Config (`latex-project.json`)

Each project has a `latex-project.json` at its root:

```json
{
  "name": "cover-letter",
  "entrypoints": [
    { "file": "main.tex", "label": "Main document" },
    { "file": "appendix.tex", "label": "Appendix only" }
  ],
  "upload": {
    "gdrive_folder_id": "1AbCdEfGhIjKlMnOp",
    "email": "maxime@example.com"
  }
}
```

- **`entrypoints`**: list of `.tex` files tectonic can compile as root documents. The first one is the default.
- **`upload.gdrive_folder_id`**: if set, the compiled PDF is auto-uploaded to this Google Drive folder after compilation. Use `gws drive` to find folder IDs.
- **`upload.email`**: if set, compilation output reminds you to send the PDF to this address. Sending is done manually via `gws gmail send` with `--attachment`.

## Scripts

All scripts live in `~/.agents/skills/latex/scripts/` (or their source in `~/aux_services/maximes-skills/skills/latex/scripts/`).

### Setup (first time only)
```bash
bash ~/.agents/skills/latex/scripts/setup.sh
```
Downloads the tectonic binary to `~/bin/tectonic`. Only needed once.

### Create a New Project
```bash
bash ~/.agents/skills/latex/scripts/new-project.sh <project-name>
# Example:
bash ~/.agents/skills/latex/scripts/new-project.sh cover-letter-acme
```
Creates the project directory with a starter `main.tex` and `latex-project.json`.

### Compile
```bash
bash ~/.agents/skills/latex/scripts/compile.sh <project-dir> [entrypoint.tex]
# Examples:
bash ~/.agents/skills/latex/scripts/compile.sh ~/.openclaw/agent_mars/correspondance/cover-letter
bash ~/.agents/skills/latex/scripts/compile.sh ~/.openclaw/agent_mars/correspondance/cover-letter letter-v2.tex
```
- Compiles from the project root so `\input{chapters/intro}` and similar work correctly.
- Output PDF lands in `<project-dir>/output/<basename>.pdf`.
- If `latex-project.json` has a `gdrive_folder_id`, the PDF is uploaded to Google Drive automatically.

## Typical Workflow

1. **Create project**: `new-project.sh <name>` (or manually mkdir + create `latex-project.json`)
2. **Edit** `main.tex` (and any included files) with your content
3. **Compile**: `compile.sh <project-dir>` — PDF appears in `output/`
4. **Share**: configure `upload` in `latex-project.json`, or use `gws gmail send` / `gws drive upload` manually

## Multi-File Projects

Tectonic runs from the project root, so `\input` and `\include` resolve relative to it:

```latex
% main.tex
\input{sections/intro}
\input{sections/conclusion}
```

Just make sure all `.tex` files are inside the project directory.

## Templates

If a `templates/` folder exists at `~/.openclaw/agent_mars/correspondance/templates/`, check it before writing a document from scratch. Templates should be self-contained `.tex` files or subdirectories with their own structure.

To use a template:
1. Copy the template into your new project directory
2. Rename the main file to match the entrypoint in `latex-project.json`
3. Edit content

## Google Drive Upload

To find the folder ID for `gdrive_folder_id`:
```bash
~/bin/gws drive list --type folder
```
The ID is the string in the `id` column.

To upload manually (without auto-upload):
```bash
~/bin/gws drive upload <path-to.pdf> --parent <folder-id>
```

## Troubleshooting

- **tectonic not found**: run `bash ~/.agents/skills/latex/scripts/setup.sh`
- **Missing packages**: tectonic downloads them automatically on first compile — just needs internet access
- **Compile errors**: check stderr output; tectonic reports line numbers and errors clearly
- **`\input` file not found**: make sure you're running `compile.sh` (which sets CWD to project root), not tectonic directly
