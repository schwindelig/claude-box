#!/bin/bash
set -e

# Fix ownership of mounted volumes (they may be created as root by Docker)
chown -R claude:claude /home/claude/.claude /workspace

CONFIG="/home/claude/.claude.json"
CONFIG_REAL="/home/claude/.claude/claude.json"

# Persist ~/.claude.json inside the mounted volume via symlink.
if [ ! -L "$CONFIG" ]; then
  rm -f "$CONFIG"
  su claude -c "ln -s '$CONFIG_REAL' '$CONFIG'"
fi

# Seed an empty config on first run.
if [ ! -f "$CONFIG_REAL" ] || [ ! -s "$CONFIG_REAL" ]; then
  su claude -c "echo '{}' > '$CONFIG_REAL'"
fi

# ── MCP servers ─────────────────────────────────────────────────────
# Register MCP servers on every startup. This ensures they are always
# present even after a rebuild, and makes it easy to add new ones.

su claude -c 'claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest 2>/dev/null || true'

# Add custom MCP servers below, for example:
# su claude -c 'claude mcp add --scope user my-server -- npx -y @my/mcp-server@latest 2>/dev/null || true'

# ────────────────────────────────────────────────────────────────────

# Drop to claude user and exec the CMD
exec su claude -c "exec $*"
