#!/usr/bin/env bash
# open-readme.sh - Open the repository README in VS Code, default GUI viewer, or less
# Usage: ./open-readme.sh
set -euo pipefail
ROOT="/workspaces/Tower-Defense"
FILE="$ROOT/README.md"
if [ ! -f "$FILE" ]; then
  echo "Error: $FILE not found." >&2
  exit 2
fi
if command -v code >/dev/null 2>&1; then
  echo "Opening $FILE in VS Code..."
  code "$FILE"
  exit 0
fi
if command -v xdg-open >/dev/null 2>&1; then
  echo "Opening $FILE with the system default application..."
  xdg-open "$FILE" &
  exit 0
fi
# fallback to less in terminal
less "$FILE"
