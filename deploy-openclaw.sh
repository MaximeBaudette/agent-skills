#!/usr/bin/env bash
# deploy-openclaw.sh — Sync skills to ~/.agents/skills/ for local development
#
# Use this when developing skills locally without pushing to GitHub.
# Changes will be picked up by OpenClaw on the next skill load.
#
# Usage:
#   bash deploy-openclaw.sh              # deploy all skills
#   bash deploy-openclaw.sh stack-summary  # deploy a specific skill

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
AGENTS_SKILLS_DIR="$HOME/.agents/skills"

deploy_skill() {
  local skill_name="$1"
  local src="$SKILLS_SRC/$skill_name"
  local dst="$AGENTS_SKILLS_DIR/$skill_name"

  if [[ ! -d "$src" ]]; then
    echo "ERROR: skill '$skill_name' not found in $SKILLS_SRC" >&2
    exit 1
  fi

  echo "→ Deploying $skill_name"
  mkdir -p "$dst"
  rsync -a --exclude='.git' "$src/" "$dst/"
  echo "  ✓ $src → $dst"
}

if [[ $# -gt 0 ]]; then
  deploy_skill "$1"
else
  echo "Deploying all skills to $AGENTS_SKILLS_DIR"
  echo ""
  for skill_dir in "$SKILLS_SRC"/*/; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    deploy_skill "$(basename "$skill_dir")"
  done
  echo ""
  echo "Done. OpenClaw will pick up changes on next skill load."
fi
