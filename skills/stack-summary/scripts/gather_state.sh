#!/usr/bin/env bash
# gather_state.sh — Collect current OpenClaw host stack state
# Output: structured text for use by an AI assistant (or render_current.py)
# Usage: bash gather_state.sh
#        bash gather_state.sh --json   (future: JSON output)
#
# Configuration (override via environment variables):
#   OPENCLAW_DIR   — path to openclaw config dir  (default: ~/.openclaw)
#   OPENCLAW_WS    — path to openclaw workspace   (default: ~/.openclaw/workspace)
#   AUX_DIR        — path to auxiliary services   (default: ~/aux_services)
#   BIN_DIR        — path to local binaries       (default: ~/bin)

set -euo pipefail

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
OPENCLAW_WS="${OPENCLAW_WS:-$HOME/.openclaw/workspace}"
OPENCLAW_CONFIG="$OPENCLAW_DIR/openclaw.json"
AUX_DIR="${AUX_DIR:-$HOME/aux_services}"
BIN_DIR="${BIN_DIR:-$HOME/bin}"

echo "=== GATHER_STATE: OpenClaw Host Stack ==="
echo "timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "host: $(hostname)"
echo ""

# --- Runtime versions ---
echo "--- RUNTIME ---"
echo "node: $(node --version 2>/dev/null || echo 'not found')"
echo "python3: $(python3 --version 2>/dev/null || echo 'not found')"
echo "npm: $(npm --version 2>/dev/null || echo 'not found')"
echo ""

# --- OpenClaw ---
echo "--- OPENCLAW ---"
openclaw --version 2>/dev/null || echo "version: unknown"

python3 - << PYEOF
import json, sys, os

config_path = os.path.expanduser("$OPENCLAW_CONFIG")
try:
    c = json.load(open(config_path))
    print(f"update_channel: {c.get('update', {}).get('channel', '?')}")
    print(f"memory_backend: {c.get('memory', {}).get('backend', '?')}")
    
    defaults = c.get('agents', {}).get('defaults', {})
    print(f"primary_model: {defaults.get('model', {}).get('primary', '?')}")
    print(f"compaction_model: {defaults.get('compaction', {}).get('model', '?')}")
    print(f"context_tokens: {defaults.get('contextTokens', '?')}")
    
    agents = [a.get('id') for a in c.get('agents', {}).get('list', [])]
    print(f"agents: {', '.join(agents)}")
    
    plugins = c.get('plugins', {}).get('entries', {})
    enabled = [k for k, v in plugins.items() if v.get('enabled', False)]
    disabled = [k for k, v in plugins.items() if not v.get('enabled', True)]
    print(f"plugins_enabled: {', '.join(enabled)}")
    if disabled:
        print(f"plugins_disabled: {', '.join(disabled)}")
    
    providers = list(c.get('models', {}).get('providers', {}).keys())
    print(f"llm_providers: {', '.join(providers)}")
except Exception as e:
    print(f"ERROR reading openclaw.json: {e}")
PYEOF
echo ""

# --- Systemd user services ---
echo "--- SYSTEMD_SERVICES ---"
systemctl --user list-units --type=service --state=active --no-pager --plain 2>/dev/null \
  | grep -v "^UNIT\|^Legend\|^$\|loaded units listed" \
  | awk '{print $1, $3}' \
  || echo "systemctl not available"
echo ""

# --- Listening ports ---
echo "--- PORTS ---"
ss -tlnp 2>/dev/null | grep LISTEN | awk '{print $4, $6}' || echo "ss not available"
echo ""

# --- Skills ---
echo "--- SKILLS ---"
ls "$OPENCLAW_DIR/skills/" 2>/dev/null | tr '\n' ' ' && echo ""
echo ""

# --- Extensions ---
echo "--- EXTENSIONS ---"
ls "$OPENCLAW_DIR/extensions/" 2>/dev/null | tr '\n' ' ' && echo ""
echo ""

# --- Auxiliary services ---
echo "--- AUX_SERVICES ---"
ls "$AUX_DIR/" 2>/dev/null | tr '\n' ' ' && echo ""
echo ""

# --- Key binaries ---
echo "--- BINARIES ---"
ls "$BIN_DIR/" 2>/dev/null | tr '\n' ' ' && echo ""
echo ""

# --- Cron registry ---
echo "--- CRONS ---"
cat "${STACK_DIR:-$HOME/STACK}/CRONs.md" 2>/dev/null || echo "CRONs.md not found at ${STACK_DIR:-$HOME/STACK}/CRONs.md"
echo ""

echo "=== END GATHER_STATE ==="
