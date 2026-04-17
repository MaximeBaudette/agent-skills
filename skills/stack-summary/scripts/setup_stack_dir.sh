#!/usr/bin/env bash
set -euo pipefail

ENV_D_DIR="${HOME}/.config/environment.d"
ENV_D_FILE="${ENV_D_DIR}/stack-dir.conf"
PROFILE_FILE="${HOME}/.profile"
BEGIN_MARKER="# >>> stack-summary STACK_DIR >>>"
END_MARKER="# <<< stack-summary STACK_DIR <<<"

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

normalize_stack_dir() {
  local candidate="$1"

  python3 - "$candidate" <<'PY'
import os
import sys

candidate = sys.argv[1].strip()
if not candidate:
    raise SystemExit(1)

expanded = os.path.expanduser(candidate)
if not os.path.isabs(expanded):
    raise SystemExit(2)

print(os.path.realpath(expanded))
PY
}

write_profile_stack_dir() {
  local resolved_path="$1"

  python3 - "$PROFILE_FILE" "$resolved_path" "$BEGIN_MARKER" "$END_MARKER" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
resolved_path = sys.argv[2]
begin_marker = sys.argv[3]
end_marker = sys.argv[4]
pattern = re.compile(r"^\s*(?:export\s+)?STACK_DIR=")

lines = path.read_text().splitlines() if path.exists() else []
cleaned = []
in_block = False

for line in lines:
    if line == begin_marker:
        in_block = True
        continue
    if in_block:
        if line == end_marker:
            in_block = False
        continue
    if pattern.match(line):
        continue
    cleaned.append(line)

while cleaned and cleaned[-1] == "":
    cleaned.pop()

block = [
    begin_marker,
    f'STACK_DIR="{resolved_path}"',
    "export STACK_DIR",
    end_marker,
]

if cleaned:
    cleaned.append("")
cleaned.extend(block)

path.write_text("\n".join(cleaned) + "\n")
PY
}

prompt_yes_no() {
  local prompt="$1"
  local answer

  while true; do
    printf "%s " "$prompt"
    IFS= read -r answer || return 1
    case "$answer" in
      [Yy]|[Yy][Ee][Ss]) return 0 ;;
      [Nn]|[Nn][Oo]|"") return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

current_exported="${STACK_DIR:-}"
current_envd="$(read_envd_stack_dir)"
current_profile="$(read_profile_stack_dir)"

persisted_value=""
if [[ -n "$current_envd" && -n "$current_profile" && "$current_envd" == "$current_profile" ]]; then
  persisted_value="$current_envd"
fi

if [[ -n "$current_exported" && -z "$current_envd" && -z "$current_profile" ]]; then
  echo "Detected exported-only STACK_DIR configuration: ${current_exported}"
  echo "Persistence is missing and setup will complete it."
elif [[ -z "$current_exported" && -z "$current_envd" && -z "$current_profile" ]]; then
  echo "STACK_DIR is not configured yet."
elif [[ -n "$current_envd" && -n "$current_profile" && "$current_envd" != "$current_profile" ]]; then
  echo "Detected persisted STACK_DIR mismatch:"
  echo "  ${ENV_D_FILE}: ${current_envd}"
  echo "  ${PROFILE_FILE}: ${current_profile}"
  echo "Setup will reconcile both persistence targets."
elif [[ -n "$current_exported" && -n "$persisted_value" && "$current_exported" != "$persisted_value" ]]; then
  echo "Detected exported STACK_DIR that conflicts with persisted configuration:"
  echo "  exported STACK_DIR: ${current_exported}"
  echo "  persisted STACK_DIR: ${persisted_value}"
  echo "Choose the value that should be persisted."
elif [[ -n "$current_envd" && -z "$current_profile" ]]; then
  echo "Detected incomplete STACK_DIR persistence: ${ENV_D_FILE} is set but ${PROFILE_FILE} is missing a managed entry."
elif [[ -z "$current_envd" && -n "$current_profile" ]]; then
  echo "Detected incomplete STACK_DIR persistence: ${PROFILE_FILE} is set but ${ENV_D_FILE} is missing."
else
  echo "Re-running STACK_DIR setup."
fi

default_answer="${current_exported:-${persisted_value:-${current_envd:-${current_profile:-}}}}"

while true; do
  if [[ -n "$default_answer" ]]; then
    printf "Desired STACK_DIR [%s]: " "$default_answer"
  else
    printf "Desired STACK_DIR: "
  fi

  IFS= read -r requested_path || {
    echo "STACK_DIR setup aborted: no input received." >&2
    exit 1
  }

  if [[ -z "$requested_path" ]]; then
    requested_path="$default_answer"
  fi

  if [[ -z "$requested_path" ]]; then
    echo "Please enter a path."
    continue
  fi

  if ! normalized_path="$(normalize_stack_dir "$requested_path")"; then
    echo "STACK_DIR must be an absolute path or start with ~."
    continue
  fi

  if [[ ! -d "$normalized_path" ]]; then
    if prompt_yes_no "Create missing directory '${normalized_path}'? [y/N]"; then
      mkdir -p "$normalized_path"
    else
      echo "Please choose an existing directory or allow setup to create it."
      continue
    fi
  fi

  if [[ ! -d "$normalized_path" ]]; then
    echo "Resolved STACK_DIR does not exist: ${normalized_path}" >&2
    exit 1
  fi

  if [[ ! -r "$normalized_path" || ! -w "$normalized_path" ]]; then
    echo "Resolved STACK_DIR must be readable and writable: ${normalized_path}" >&2
    exit 1
  fi

  mkdir -p "$ENV_D_DIR"
  printf 'STACK_DIR=%s\n' "$normalized_path" > "$ENV_D_FILE"
  write_profile_stack_dir "$normalized_path"
  export STACK_DIR="$normalized_path"

  echo ""
  echo "STACK_DIR configured: ${STACK_DIR}"
  echo "Updated persistence targets:"
  echo "  - ${ENV_D_FILE}"
  echo "  - ${PROFILE_FILE}"
  echo ""
  echo "Next steps:"
  echo "  1. Start a fresh login shell or run: source \"${PROFILE_FILE}\""
  echo "  2. Run: systemctl --user import-environment STACK_DIR"
  echo "  3. Restart Hermes gateways:"
  echo "     - systemctl --user restart hermes-gateway.service"
  echo "     - systemctl --user restart hermes-gateway-career-manager.service"
  echo "     - systemctl --user restart hermes-gateway-health-coach.service"
  break
done
