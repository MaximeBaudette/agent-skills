#!/usr/bin/env bash
# new-project.sh — Scaffold a new LaTeX project under correspondance/
#
# Usage:
#   bash new-project.sh <project-name> [correspondance-dir]
#
# Creates:
#   <correspondance-dir>/<project-name>/
#   ├── latex-project.json
#   ├── main.tex            (minimal starter)
#   └── output/             (gitignored, created on first compile)

set -euo pipefail

PROJECT_NAME="${1:-}"
CORRESPONDANCE_DIR="${2:-$HOME/.openclaw/agent_mars/correspondance}"

if [[ -z "$PROJECT_NAME" ]]; then
  echo "Usage: new-project.sh <project-name> [correspondance-dir]" >&2
  exit 1
fi

PROJECT_DIR="$CORRESPONDANCE_DIR/$PROJECT_NAME"

if [[ -d "$PROJECT_DIR" ]]; then
  echo "ERROR: project already exists: $PROJECT_DIR" >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR/output"

# Create default latex-project.json
cat > "$PROJECT_DIR/latex-project.json" <<EOF
{
  "name": "$PROJECT_NAME",
  "entrypoints": [
    { "file": "main.tex", "label": "Main document" }
  ],
  "upload": {
    "gdrive_folder_id": null,
    "email": null
  }
}
EOF

# Create minimal starter main.tex
cat > "$PROJECT_DIR/main.tex" <<'EOF'
\documentclass[12pt]{article}
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{geometry}
\geometry{margin=1in}

\title{Document Title}
\author{Author Name}
\date{\today}

\begin{document}

\maketitle

\section{Introduction}

Write your content here.

\end{document}
EOF

# Add output/ to gitignore for this project
echo "output/" > "$PROJECT_DIR/.gitignore"

echo "✓ Project created: $PROJECT_DIR"
echo ""
echo "Files:"
echo "  $PROJECT_DIR/latex-project.json   ← configure entrypoints and upload targets"
echo "  $PROJECT_DIR/main.tex             ← edit your LaTeX here"
echo "  $PROJECT_DIR/output/              ← compiled PDFs go here (gitignored)"
echo ""
echo "To compile:"
echo "  bash compile.sh \"$PROJECT_DIR\""
