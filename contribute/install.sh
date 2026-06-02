#!/bin/bash

set -e

COMMANDS_DIR="$HOME/.claude/commands"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$REPO_DIR/commands/mtx.md"

mkdir -p "$COMMANDS_DIR"

if ln -sf "$SOURCE_FILE" "$COMMANDS_DIR/mtx.md" 2>/dev/null; then
    echo "✓ /mtx installed (symlinked) and ready"
    echo "  Updates to commands/mtx.md will be available automatically after git pull"
else
    cp "$SOURCE_FILE" "$COMMANDS_DIR/mtx.md"
    echo "✓ /mtx installed (copied) and ready"
    echo "  Tip: run ./install.sh again after git pull to get the latest version"
fi
