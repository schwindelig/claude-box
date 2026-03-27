#!/bin/bash
set -e

CLAUDE_DIR="$HOME/.claude"
CONFIG="$HOME/.claude.json"
CONFIG_REAL="$CLAUDE_DIR/claude.json"

# Persist ~/.claude.json inside the mounted volume via symlink.
# Claude Code writes to ~/.claude.json, but only ~/.claude/ is mounted.
# By symlinking, the actual file lives inside the volume.
if [ ! -L "$CONFIG" ]; then
  rm -f "$CONFIG"
  ln -s "$CONFIG_REAL" "$CONFIG"
fi

# Seed an empty config on first run.
if [ ! -f "$CONFIG_REAL" ] || [ ! -s "$CONFIG_REAL" ]; then
  echo '{}' > "$CONFIG_REAL"
fi

# ── MCP servers ─────────────────────────────────────────────────────
# Register MCP servers on every startup. This ensures they're always
# present even after a rebuild, and makes it easy to add new ones.

claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest 2>/dev/null || true

# Add custom MCP servers below, for example:
# claude mcp add --scope user my-server -- npx -y @my/mcp-server@latest 2>/dev/null || true

# ────────────────────────────────────────────────────────────────────

exec "$@"
