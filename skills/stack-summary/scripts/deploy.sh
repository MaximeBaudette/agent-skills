#!/usr/bin/env bash
# deploy.sh — Sync stack-summary skill to ~/.agents/skills/stack-summary
# Run this after making changes to SKILL.md or scripts/ to update the OpenClaw install.
# Usage: bash scripts/deploy.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AGENTS_SKILL_DIR="$HOME/.agents/skills/stack-summary"

echo "Syncing $SKILL_DIR → $AGENTS_SKILL_DIR"

rsync -av --exclude='.git' "$SKILL_DIR/" "$AGENTS_SKILL_DIR/"

echo "Done. OpenClaw will pick up changes on next skill load."
