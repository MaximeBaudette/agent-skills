---
name: latex
description: Compile LaTeX documents using the Tectonic engine. Use this skill whenever the user wants to create, edit, or compile a LaTeX document — letters, articles, CVs, reports. Tectonic is a self-contained compiler that auto-downloads only the packages it needs.
metadata:
  { "openclaw": { "emoji": "📄", "os": ["linux", "darwin"] } }
---

# LaTeX Skill (via Tectonic)

## Key facts

- **Compiler:** [Tectonic](https://tectonic-typesetting.github.io/) — single binary, auto-downloads packages on first compile, no full TeX Live needed
- **Projects live in:** `~/.openclaw/agent_mars/correspondance/<project-name>/`
- **Output always goes to:** `<project-dir>/output/<name>.pdf`
- **Multi-file works:** tectonic resolves `\input{}` relative to where you run it from

---

## Setup (first time — or if compile fails with "tectonic not found")

**Step 1: Check if tectonic is already available**
```bash
command -v tectonic || ls $HOME/bin/tectonic 2>/dev/null || echo "NOT FOUND"
```

**Step 2: If not found, install it**
```bash
bash ~/.agents/skills/latex/scripts/setup.sh
```
This downloads the tectonic binary from GitHub releases into `~/bin/`. Only needed once per machine.

**Step 3: Confirm**
```bash
$(command -v tectonic || echo $HOME/bin/tectonic) --version
```
Expected output: `tectonic X.Y.Z`

---

## Task 1 — Create a new project

Do these steps in order. No exploration needed.

**Step 1:** Create the directory structure
```bash
mkdir -p /home/mars/.openclaw/agent_mars/correspondance/PROJECT_NAME/output
```

**Step 2:** Create `/home/mars/.openclaw/agent_mars/correspondance/PROJECT_NAME/latex-project.json`
```json
{
  "name": "PROJECT_NAME",
  "entrypoints": [
    { "file": "main.tex", "label": "Main document" }
  ],
  "upload": {
    "gdrive_folder_id": null,
    "email": null
  }
}
```

**Step 3:** Create `/home/mars/.openclaw/agent_mars/correspondance/PROJECT_NAME/main.tex` with the document content.

**Step 4:** Create `/home/mars/.openclaw/agent_mars/correspondance/PROJECT_NAME/.gitignore`
```
output/
```

---

## Task 2 — Compile a project

**One command — run from the project directory:**
```bash
TECTONIC=$(command -v tectonic || echo $HOME/bin/tectonic) && cd /home/mars/.openclaw/agent_mars/correspondance/PROJECT_NAME && mkdir -p output && $TECTONIC --outdir output main.tex
```

Replace `main.tex` with the actual entrypoint filename if different.

**Output PDF will be at:**
```
/home/mars/.openclaw/agent_mars/correspondance/PROJECT_NAME/output/main.pdf
```

For multi-entrypoint projects, check `latex-project.json` to see the list of `.tex` files, then compile each one the same way.

---

## Task 3 — Upload / share the PDF

### Upload to Google Drive
```bash
/home/mars/bin/gws drive upload /home/mars/.openclaw/agent_mars/correspondance/PROJECT_NAME/output/main.pdf --parent FOLDER_ID
```
To find a Drive folder ID: `~/bin/gws drive list --type folder`

### Send by email (as attachment)
Use the gws-gmail skill. The PDF is at:
`/home/mars/.openclaw/agent_mars/correspondance/PROJECT_NAME/output/main.pdf`

### Auto-upload on compile
Set `gdrive_folder_id` or `email` in `latex-project.json`. Then run:
```bash
bash /home/mars/.agents/skills/latex/scripts/compile.sh /home/mars/.openclaw/agent_mars/correspondance/PROJECT_NAME
```
The compile script handles auto-upload when those fields are set.

---

## Templates

Before writing a document from scratch, check if `/home/mars/.openclaw/agent_mars/correspondance/templates/` exists. If it does, look for a suitable template there and copy it into the new project directory.

---

## Compile errors

Tectonic prints errors with file name and line number. Read the output carefully — it is usually a missing `\end{}`, typo in a package name, or encoding issue. Fix the `.tex` file and re-run the compile command.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `tectonic: command not found` | Run setup: `bash ~/.agents/skills/latex/scripts/setup.sh` |
| `cannot find file X.tex` | Make sure you `cd` into the project dir before running tectonic |
| Packages downloading slowly | Normal on first compile — tectonic auto-downloads only what's needed |
| `\input{file}` not found | Run tectonic from the project root (the `cd` command above handles this) |
