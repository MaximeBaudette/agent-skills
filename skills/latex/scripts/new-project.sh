#!/usr/bin/env bash
# new-project.sh — Scaffold a new LaTeX project ready for multiple entrypoints + shared files
#
# Usage:
#   bash new-project.sh <project-name> [correspondance-root]
#
# The script defaults to supporting multi-document projects from day one.
# It creates a common/ directory for shared includes and a latex-project.json
# with an entrypoints array.
#
# After creation, agents can easily add more entrypoints later.

set -euo pipefail

PROJECT_NAME="${1:-}"
CORRESPONDANCE_ROOT="${2:-${CORRESPONDANCE_ROOT:-}}"

if [[ -z "$PROJECT_NAME" ]]; then
  echo "Usage: new-project.sh <project-name> [correspondance-root]" >&2
  echo "" >&2
  echo "If correspondance-root is omitted, the script uses \$CORRESPONDANCE_ROOT" >&2
  echo "or falls back to the current working directory." >&2
  exit 1
fi

if [[ -z "$CORRESPONDANCE_ROOT" ]]; then
  CORRESPONDANCE_ROOT="$(pwd)"
fi

CORRESPONDANCE_ROOT="$(realpath "$CORRESPONDANCE_ROOT")"
PROJECT_DIR="$CORRESPONDANCE_ROOT/$PROJECT_NAME"

if [[ -d "$PROJECT_DIR" ]]; then
  echo "ERROR: Project already exists: $PROJECT_DIR" >&2
  exit 1
fi

echo "→ Creating project: $PROJECT_DIR"

mkdir -p "$PROJECT_DIR/common"
mkdir -p "$PROJECT_DIR/output"

# Create latex-project.json with multi-entrypoint support
cat > "$PROJECT_DIR/latex-project.json" <<EOF
{
  "name": "$PROJECT_NAME",
  "entrypoints": [
    {
      "file": "main.tex",
      "label": "Main Document"
    }
  ],
  "upload": {
    "gdrive_folder_id": null,
    "email": null
  }
}
EOF

# Create a starter main.tex that demonstrates including from common/
cat > "$PROJECT_DIR/main.tex" <<'EOF'
\documentclass[12pt]{article}
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{geometry}
\geometry{margin=1in}

% Shared content
\input{common/constants}
\input{common/letterhead}

\title{Document Title}
\author{Author Name}
\date{\today}

\begin{document}

\maketitle

\section{Introduction}

Write your content here.

\end{document}
EOF

# Create example shared files in common/
cat > "$PROJECT_DIR/common/constants.tex" <<'EOF'
% Common constants and variables for this project
% Edit these values and they will be reflected across all documents that input this file.

\newcommand{\ProjectTitle}{Document Title}
\newcommand{\ProjectDate}{\today}
EOF

cat > "$PROJECT_DIR/common/letterhead.tex" <<'EOF'
% Shared letterhead / header definitions
% Customize as needed for this project or profile.
EOF

# Create .gitignore
cat > "$PROJECT_DIR/.gitignore" <<EOF
output/
*.aux
*.log
*.out
*.toc
*.synctex.gz
EOF

echo ""
echo "✓ Project created successfully: $PROJECT_DIR"
echo ""
echo "Structure:"
echo "  $PROJECT_DIR/latex-project.json"
echo "  $PROJECT_DIR/main.tex                 ← first entrypoint"
echo "  $PROJECT_DIR/common/                  ← shared files (input from entrypoints)"
echo "  $PROJECT_DIR/output/                  ← compiled PDFs (gitignored)"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_DIR"
echo "  2. Edit latex-project.json to add more entrypoints if needed"
echo "  3. Compile all entrypoints:"
echo "     bash ~/.hermes/skills/latex/scripts/compile.sh ."
echo "  4. Or compile one specific document:"
echo "     bash ~/.hermes/skills/latex/scripts/compile.sh . main.tex"
echo ""
echo "Tip: Read latex-project.json to discover all available entrypoints in this project."
