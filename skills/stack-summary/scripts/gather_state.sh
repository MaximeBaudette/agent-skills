#!/usr/bin/env bash
# gather_state.sh — Collect current agent host stack state (Hermes priority)
# Output: structured text for use by an AI assistant
# Usage: bash gather_state.sh
#   Interactive runs without STACK_DIR setup hand off to setup_stack_dir.sh.
#   Non-interactive runs fail until STACK_DIR setup is complete.
#
# Configuration (override via environment variables):
#   HERMES_DIR    — path to hermes config dir     (default: ~/.hermes)
#   AUX_DIR       — path to auxiliary services    (default: ~/aux_services)
#   BIN_DIR       — path to local binaries        (default: ~/bin)
#   STACK_DIR     — path to STACK docs            (default: ~/STACK)

set -euo pipefail

HERMES_DIR="${HERMES_DIR:-$HOME/.hermes}"
AUX_DIR="${AUX_DIR:-$HOME/aux_services}"
BIN_DIR="${BIN_DIR:-$HOME/bin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/ensure_stack_dir.sh"
STACK_DIR="${STACK_DIR:-$HOME/STACK}"

echo "=== GATHER_STATE: Agent Host Stack (Hermes $(date -u +%Y-%m-%dT%H:%M:%SZ)) ==="
echo "host: $(hostname)"
echo ""

# --- Runtime versions ---
echo "--- RUNTIME ---"
echo "node: $(node --version 2>/dev/null || echo 'not found')"
echo "python3: $(python3 --version 2>/dev/null || echo 'not found')"
echo "npm: $(npm --version 2>/dev/null || echo 'not found')"
echo ""

# --- Agent Frameworks ---
echo "--- AGENT_FRAMEWORKS ---"
if command -v hermes >/dev/null 2>&1; then
  echo "hermes: $(hermes --version 2>/dev/null || echo 'installed')"
  echo "profiles: $(ls "$HERMES_DIR"/profiles/ 2>/dev/null | tr '\n' ' ' || echo 'none')"
  echo "skills:"
  hermes skills list 2>/dev/null || echo "skills list unavailable"
  echo "crons (default profile):"
  hermes cron list 2>/dev/null || echo "crons list unavailable"
  echo ""
fi
if command -v openclaw >/dev/null 2>&1; then
  echo "openclaw: $(openclaw --version 2>/dev/null || echo 'installed')"
  openclaw status 2>/dev/null || true
  echo ""
fi

# --- Systemd user services ---
echo "--- SYSTEMD_SERVICES ---"
systemctl --user list-units --type=service --state=active --no-pager --plain 2>/dev/null \
  | grep -v "^UNIT\|^Legend\|^$" \
  | awk '{print $1, $3}' \
  || echo "systemctl not available"
echo ""

# --- Listening ports ---
echo "--- PORTS ---"
ss -tlnp 2>/dev/null | grep LISTEN | awk '{print $4, $6}' || echo "ss not available"
echo ""

# --- Skills dirs ---
echo "--- SKILLS_DIRS ---"
ls "$HERMES_DIR/skills/" 2>/dev/null | tr '\n' ' ' && echo "" || echo "no skills dir"
echo ""

# --- Auxiliary services ---
echo "--- AUX_SERVICES ---"
ls "$AUX_DIR/" 2>/dev/null | tr '\n' ' ' && echo ""
echo ""

# --- Key binaries ---
echo "--- BINARIES ---"
ls "$BIN_DIR/" 2>/dev/null | head -10 | tr '\n' ' ' && echo ""
echo ""

# --- Cron registry ---
echo "--- CRONS_REGISTRY ---"
cat "${STACK_DIR}/CRONs.md" 2>/dev/null || echo "CRONs.md not found"
echo ""

echo "=== END GATHER_STATE ==="
