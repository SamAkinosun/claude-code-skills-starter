#!/usr/bin/env bash
# Fires a macOS notification when Claude Code finishes a turn (Stop event).
# On Linux, falls back to notify-send. On Windows / WSL, no-op with a friendly note.
#
# Reads the Stop hook payload from stdin but does not require any field.
# Always exits 0 so it never blocks.

set -uo pipefail

# Drain stdin so the parent process does not hang on a broken pipe.
cat > /dev/null

TITLE="Claude Code"
MESSAGE="Turn complete in $(basename "$PWD")"

case "$(uname -s)" in
  Darwin)
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null || true
    ;;
  Linux)
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "$TITLE" "$MESSAGE" 2>/dev/null || true
    fi
    ;;
  *)
    # No-op on other platforms. Edit this hook to add your own notifier.
    :
    ;;
esac

exit 0
