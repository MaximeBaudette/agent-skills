# Example Multi-Document LaTeX Project

This is a minimal example of a LaTeX project designed for multiple independently compilable documents that share common files.

## Structure

```
example-multi-document-project/
├── latex-project.json          # Declares the entrypoints
├── cover-letter.tex            # One entrypoint
├── motivation-letter.tex       # Another entrypoint
├── common/
│   ├── constants.tex           # Shared variables
│   └── letterhead.tex          # Shared formatting
├── .gitignore
└── output/                     # Generated PDFs (gitignored)
```

## Usage

1. Copy this folder into your profile's `CORRESPONDANCE_ROOT`.

2. Rename the folder to something meaningful.

3. Edit `latex-project.json` and add/remove entrypoints as needed.

4. Edit the files in `common/` with your actual constants and letterhead.

5. Compile:

   ```bash
   # Compile everything
   bash ~/.hermes/skills/latex/scripts/compile.sh .

   # Or only one document
   bash ~/.hermes/skills/latex/scripts/compile.sh . cover-letter.tex
   ```

## Key Points

- All entrypoints are listed in `latex-project.json`.
- Shared files live in `common/` and are `\input`ed by the entrypoints.
- PDFs are named after their source `.tex` file.
- This pattern scales well for document packages (multiple related letters, application bundles, etc.).

See the main `skills/latex/SKILL.md` for full documentation.
