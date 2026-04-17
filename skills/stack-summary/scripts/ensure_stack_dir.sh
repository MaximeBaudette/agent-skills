#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_SCRIPT="${SCRIPT_DIR}/setup_stack_dir.sh"
ENV_D_FILE="${HOME}/.config/environment.d/stack-dir.conf"
PROFILE_FILE="${HOME}/.profile"
BEGIN_MARKER="# >>> stack-summary STACK_DIR >>>"
END_MARKER="# <<< stack-summary STACK_DIR <<<"

is_sourced() {
  [[ "${BASH_SOURCE[0]}" != "$0" ]]
}

finish() {
  local status="$1"
  if is_sourced; then
    return "$status"
  fi
  exit "$status"
}

read_envd_stack_dir() {
  python3 - "$ENV_D_FILE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
if not path.exists():
    raise SystemExit(0)

for raw_line in path.read_text().splitlines():
    line = raw_line.strip()
    if not line or line.startswith("#") or not line.startswith("STACK_DIR="):
        continue
    value = line.split("=", 1)[1].strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        value = value[1:-1]
    print(value)
    break
PY
}

read_profile_stack_dir() {
  python3 - "$PROFILE_FILE" "$BEGIN_MARKER" "$END_MARKER" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
begin_marker = sys.argv[2]
end_marker = sys.argv[3]
pattern = re.compile(r"^\s*(?:export\s+)?STACK_DIR=(.*)$")

if not path.exists():
    raise SystemExit(0)

lines = path.read_text().splitlines()
in_block = False
managed_match = None
fallback_match = None

for line in lines:
    if line == begin_marker:
        in_block = True
        continue
    if line == end_marker:
        in_block = False
        continue

    match = pattern.match(line)
    if not match:
        continue

    value = match.group(1).strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        value = value[1:-1]

    if in_block:
        managed_match = value
    else:
        fallback_match = value

print(managed_match or fallback_match or "")
PY
}

handoff_or_fail() {
  local message="$1"

  if [[ -t 0 && -t 1 ]]; then
    echo "$message" >&2
    if is_sourced && [[ $- == *i* ]]; then
      "$SETUP_SCRIPT"
      finish $?
    fi
    exec "$SETUP_SCRIPT"
  fi

  echo "$message" >&2
  finish 1
}

exported_stack_dir="${STACK_DIR:-}"
envd_stack_dir="$(read_envd_stack_dir)"
profile_stack_dir="$(read_profile_stack_dir)"
resolved_stack_dir=""

if [[ -n "$exported_stack_dir" ]]; then
  if [[ -z "$envd_stack_dir" && -z "$profile_stack_dir" ]]; then
    handoff_or_fail "STACK_DIR setup required: exported STACK_DIR is set, but persistence is missing. Run ${SETUP_SCRIPT} to persist it."
  fi

  if [[ -n "$envd_stack_dir" && -z "$profile_stack_dir" ]] || [[ -z "$envd_stack_dir" && -n "$profile_stack_dir" ]]; then
    handoff_or_fail "STACK_DIR reconcile required: persistence is incomplete. Run ${SETUP_SCRIPT} to reconcile ${ENV_D_FILE} and ${PROFILE_FILE}."
  fi

  if [[ -n "$envd_stack_dir" && -n "$profile_stack_dir" && "$envd_stack_dir" != "$profile_stack_dir" ]]; then
    handoff_or_fail "STACK_DIR reconcile required: persisted files disagree (${ENV_D_FILE} vs ${PROFILE_FILE}). Run ${SETUP_SCRIPT} to reconcile them."
  fi

  if [[ -n "$envd_stack_dir" && "$exported_stack_dir" != "$envd_stack_dir" ]]; then
    handoff_or_fail "STACK_DIR reconcile required: exported STACK_DIR (${exported_stack_dir}) conflicts with persisted configuration (${envd_stack_dir}). Run ${SETUP_SCRIPT}."
  fi

  resolved_stack_dir="$exported_stack_dir"
else
  if [[ -z "$envd_stack_dir" && -z "$profile_stack_dir" ]]; then
    handoff_or_fail "STACK_DIR setup required: no configuration found. Run ${SETUP_SCRIPT} to configure STACK_DIR."
  fi

  if [[ -n "$envd_stack_dir" && -z "$profile_stack_dir" ]] || [[ -z "$envd_stack_dir" && -n "$profile_stack_dir" ]]; then
    handoff_or_fail "STACK_DIR reconcile required: persistence is incomplete. Run ${SETUP_SCRIPT} to reconcile ${ENV_D_FILE} and ${PROFILE_FILE}."
  fi

  if [[ "$envd_stack_dir" != "$profile_stack_dir" ]]; then
    handoff_or_fail "STACK_DIR reconcile required: persisted files disagree (${ENV_D_FILE} vs ${PROFILE_FILE}). Run ${SETUP_SCRIPT} to reconcile them."
  fi

  resolved_stack_dir="$envd_stack_dir"
  export STACK_DIR="$resolved_stack_dir"
fi

if [[ ! -d "$resolved_stack_dir" ]]; then
  echo "STACK_DIR is configured, but the directory does not exist: ${resolved_stack_dir}" >&2
  finish 1
fi

export STACK_DIR="$resolved_stack_dir"

if ! is_sourced; then
  finish 0
fi
