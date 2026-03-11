#!/usr/bin/env bash
# deploy.sh — Sync this skill to ~/.agents/skills/stack-summary
# Convenience wrapper around the monorepo root deploy-openclaw.sh.
# Usage: bash scripts/deploy.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Try to delegate to the monorepo root script if available
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [[ -x "$REPO_ROOT/deploy-openclaw.sh" ]]; then
  exec bash "$REPO_ROOT/deploy-openclaw.sh" stack-summary
fi

# Fallback: standalone install (skill cloned directly, not inside monorepo)
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENTS_SKILL_DIR="$HOME/.agents/skills/stack-summary"
echo "Syncing $SKILL_DIR → $AGENTS_SKILL_DIR"
rsync -a --exclude='.git' "$SKILL_DIR/" "$AGENTS_SKILL_DIR/"
echo "Done. OpenClaw will pick up changes on next skill load."
