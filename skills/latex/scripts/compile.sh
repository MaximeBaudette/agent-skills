#!/usr/bin/env bash
# compile.sh — Compile a LaTeX project using tectonic
#
# Usage:
#   bash compile.sh <project-dir> [entrypoint.tex]
#
# - project-dir:   path to the project folder (contains latex-project.json)
# - entrypoint:    .tex file to compile (default: read from latex-project.json,
#                  or falls back to main.tex)
#
# Output PDF is written to <project-dir>/output/<entrypoint-basename>.pdf
#
# Examples:
#   bash compile.sh ~/.openclaw/agent_mars/correspondance/cover-letter
#   bash compile.sh ~/.openclaw/agent_mars/correspondance/cover-letter letter.tex

set -euo pipefail

PROJECT_DIR="${1:-}"
ENTRYPOINT="${2:-}"

if [[ -z "$PROJECT_DIR" ]]; then
  echo "Usage: compile.sh <project-dir> [entrypoint.tex]" >&2
  exit 1
fi

PROJECT_DIR="$(realpath "$PROJECT_DIR")"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: project directory not found: $PROJECT_DIR" >&2
  exit 1
fi

# Resolve entrypoint
if [[ -z "$ENTRYPOINT" ]]; then
  CONFIG="$PROJECT_DIR/latex-project.json"
  if [[ -f "$CONFIG" ]]; then
    # Read first entrypoint from config
    ENTRYPOINT=$(python3 -c "
import json, sys
cfg = json.load(open('$CONFIG'))
eps = cfg.get('entrypoints', [])
if eps:
    print(eps[0]['file'])
else:
    print('main.tex')
" 2>/dev/null || echo "main.tex")
  else
    ENTRYPOINT="main.tex"
  fi
fi

TEX_FILE="$PROJECT_DIR/$ENTRYPOINT"

if [[ ! -f "$TEX_FILE" ]]; then
  echo "ERROR: entrypoint not found: $TEX_FILE" >&2
  exit 1
fi

OUTPUT_DIR="$PROJECT_DIR/output"
mkdir -p "$OUTPUT_DIR"

# Find tectonic
TECTONIC=$(command -v tectonic 2>/dev/null || echo "$HOME/bin/tectonic")
if [[ ! -x "$TECTONIC" ]]; then
  echo "ERROR: tectonic not found. Run: bash setup.sh" >&2
  exit 1
fi

echo "→ Compiling: $ENTRYPOINT"
echo "   Project:  $PROJECT_DIR"
echo "   Output:   $OUTPUT_DIR"

# Run tectonic from the project dir so \input / \include resolve correctly
cd "$PROJECT_DIR"
"$TECTONIC" --outdir "$OUTPUT_DIR" "$ENTRYPOINT"

BASENAME=$(basename "$ENTRYPOINT" .tex)
PDF="$OUTPUT_DIR/$BASENAME.pdf"

if [[ -f "$PDF" ]]; then
  echo "✓ Compiled successfully: $PDF"
else
  echo "ERROR: expected output not found: $PDF" >&2
  exit 1
fi

# Check if upload is configured
CONFIG="$PROJECT_DIR/latex-project.json"
if [[ -f "$CONFIG" ]]; then
  GDRIVE_FOLDER=$(python3 -c "
import json, sys
cfg = json.load(open('$CONFIG'))
print(cfg.get('upload', {}).get('gdrive_folder_id') or '')
" 2>/dev/null || echo "")

  EMAIL_TO=$(python3 -c "
import json, sys
cfg = json.load(open('$CONFIG'))
print(cfg.get('upload', {}).get('email') or '')
" 2>/dev/null || echo "")

  if [[ -n "$GDRIVE_FOLDER" ]]; then
    echo "→ Uploading to Google Drive folder: $GDRIVE_FOLDER"
    if command -v gws &>/dev/null || [[ -x "$HOME/bin/gws" ]]; then
      GWS=$(command -v gws 2>/dev/null || echo "$HOME/bin/gws")
      "$GWS" drive upload "$PDF" --parent "$GDRIVE_FOLDER" && echo "✓ Uploaded to Google Drive"
    else
      echo "⚠  gws not found — skipping Google Drive upload"
    fi
  fi

  if [[ -n "$EMAIL_TO" ]]; then
    echo "→ Email upload configured for: $EMAIL_TO"
    echo "   (Use gws gmail to send $PDF as attachment)"
  fi
fi
