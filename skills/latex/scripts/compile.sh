#!/usr/bin/env bash
# compile.sh — Compile LaTeX entrypoints for a project
#
# Usage:
#   bash compile.sh <project-dir> [entrypoint.tex]
#
# Behavior:
#   - If no entrypoint is given → compile ALL entrypoints listed in latex-project.json
#   - If an entrypoint is given  → compile only that one
#
# Output PDFs are written to <project-dir>/output/ named after the .tex file.
#
# Examples:
#   bash compile.sh /path/to/project
#   bash compile.sh /path/to/project cover-letter.tex

set -euo pipefail

PROJECT_DIR="${1:-}"
SPECIFIC_ENTRYPOINT="${2:-}"

if [[ -z "$PROJECT_DIR" ]]; then
  echo "Usage: compile.sh <project-dir> [entrypoint.tex]" >&2
  exit 1
fi

PROJECT_DIR="$(realpath "$PROJECT_DIR")"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: Project directory not found: $PROJECT_DIR" >&2
  exit 1
fi

CONFIG="$PROJECT_DIR/latex-project.json"

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: latex-project.json not found in $PROJECT_DIR" >&2
  exit 1
fi

# Find tectonic
TECTONIC=$(command -v tectonic 2>/dev/null || echo "$HOME/bin/tectonic")
if [[ ! -x "$TECTONIC" ]]; then
  echo "ERROR: tectonic not found. Run: bash ~/.hermes/skills/latex/scripts/setup.sh" >&2
  exit 1
fi

OUTPUT_DIR="$PROJECT_DIR/output"
mkdir -p "$OUTPUT_DIR"

# Change to project root so relative \input / \include work correctly
cd "$PROJECT_DIR"

# Determine which entrypoints to compile
if [[ -n "$SPECIFIC_ENTRYPOINT" ]]; then
  ENTRYPOINTS=("$SPECIFIC_ENTRYPOINT")
else
  # Read all entrypoints from the JSON
  mapfile -t ENTRYPOINTS < <(python3 -c "
import json, sys
cfg = json.load(open('$CONFIG'))
for ep in cfg.get('entrypoints', []):
    print(ep.get('file', ''))
" 2>/dev/null)
fi

if [[ ${#ENTRYPOINTS[@]} -eq 0 || -z "${ENTRYPOINTS[0]}" ]]; then
  echo "ERROR: No entrypoints found in latex-project.json and none provided on command line." >&2
  exit 1
fi

echo "Project: $PROJECT_DIR"
echo "Compiling ${#ENTRYPOINTS[@]} document(s)..."
echo ""

FAILED=()

for ENTRYPOINT in "${ENTRYPOINTS[@]}"; do
  [[ -z "$ENTRYPOINT" ]] && continue

  TEX_FILE="$PROJECT_DIR/$ENTRYPOINT"

  if [[ ! -f "$TEX_FILE" ]]; then
    echo "✗ ERROR: Entrypoint not found: $ENTRYPOINT" >&2
    FAILED+=("$ENTRYPOINT")
    continue
  fi

  BASENAME=$(basename "$ENTRYPOINT" .tex)
  PDF="$OUTPUT_DIR/$BASENAME.pdf"

  echo "→ Compiling: $ENTRYPOINT"
  echo "   Output:   $PDF"

  if "$TECTONIC" --outdir "$OUTPUT_DIR" "$ENTRYPOINT"; then
    if [[ -f "$PDF" ]]; then
      echo "✓ Success: $PDF"
    else
      echo "✗ ERROR: Expected PDF not created: $PDF" >&2
      FAILED+=("$ENTRYPOINT")
    fi
  else
    echo "✗ ERROR: Compilation failed for $ENTRYPOINT" >&2
    FAILED+=("$ENTRYPOINT")
  fi
  echo ""
done

# Optional upload handling (project-level for now)
if [[ -f "$CONFIG" ]]; then
  GDRIVE_FOLDER=$(python3 -c "
import json, sys
cfg = json.load(open('$CONFIG'))
print(cfg.get('upload', {}).get('gdrive_folder_id') or '')
" 2>/dev/null || echo "")

  if [[ -n "$GDRIVE_FOLDER" ]]; then
    echo "→ Project has Google Drive upload configured: $GDRIVE_FOLDER"
    echo "   (Upload individual PDFs manually using the google-workspace skill or gws)"
  fi
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "Some documents failed to compile:" >&2
  printf '  - %s\n' "${FAILED[@]}" >&2
  exit 1
else
  echo "All requested documents compiled successfully."
fi
