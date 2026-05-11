#!/usr/bin/env bash
# Blocks Write/Edit operations whose content matches obvious secret patterns.
# Reads the Claude Code PreToolUse hook payload from stdin (JSON).
# Exit codes:
#   0 = allow the tool call
#   2 = block the tool call (stderr message is returned to the model)
#
# This script intentionally errs on the side of blocking. False positives
# are easier to diagnose than a leaked key.

set -uo pipefail

PAYLOAD="$(cat)"

# Extract fields with python so we do not need jq.
extract() {
  PAYLOAD="$PAYLOAD" python3 - "$1" <<'PY'
import json, os, sys
path = sys.argv[1].split(".")
try:
    val = json.loads(os.environ["PAYLOAD"])
except Exception:
    print("")
    sys.exit(0)
for key in path:
    if isinstance(val, dict):
        val = val.get(key, "")
    else:
        val = ""
        break
print(val if isinstance(val, str) else "")
PY
}

TOOL_NAME="$(extract tool_name)"
FILE_PATH="$(extract tool_input.file_path)"

case "$TOOL_NAME" in
  Write)
    CONTENT="$(extract tool_input.content)"
    ;;
  Edit)
    CONTENT="$(extract tool_input.new_string)"
    ;;
  *)
    exit 0
    ;;
esac

# Skip files where secrets are expected to appear as examples.
case "$FILE_PATH" in
  *.env.example|*/SECRETS.md|*/secrets.example.*) exit 0 ;;
esac

# Patterns. Each line: regex<TAB>human label.
PATTERNS=$'sk-[A-Za-z0-9]{20,}\tOpenAI / Anthropic-style API key\nghp_[A-Za-z0-9]{36}\tGitHub personal access token\nghs_[A-Za-z0-9]{36}\tGitHub server-to-server token\nAKIA[0-9A-Z]{16}\tAWS access key ID\nxox[bpoasr]-[A-Za-z0-9-]{10,}\tSlack token\n-----BEGIN [A-Z ]*PRIVATE KEY-----\tPrivate key block'

while IFS=$'\t' read -r pattern label; do
  [ -z "$pattern" ] && continue
  if printf '%s' "$CONTENT" | grep -Eq -e "$pattern"; then
    echo "block-secrets.sh: refused to write $FILE_PATH" >&2
    echo "matched pattern for: $label" >&2
    echo "if this is a false positive, move the value into an environment" >&2
    echo "variable or .env file (which is gitignored) and reference it from code." >&2
    exit 2
  fi
done <<< "$PATTERNS"

exit 0
