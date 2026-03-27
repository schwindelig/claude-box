# claude-box

Self-contained Docker environment for running [Claude Code](https://docs.anthropic.com/en/docs/claude-code). The container stays running 24/7 and can be used interactively via `docker exec`, headlessly with `claude -p`, or remotely via `claude remote-control`. Authenticates via OAuth by default (uses your Pro/Max plan), with optional API key override.

## Prerequisites

- Docker and Docker Compose
- A Claude Pro or Max subscription (for OAuth), or an [Anthropic API key](https://console.anthropic.com/) (for Console billing)

## Setup

```bash
# 1. Clone this repo
git clone https://github.com/schwindelig/claude-box.git && cd claude-box

# 2. Create your .env file
cp .env.example .env
# Only edit .env if you want to use an API key instead of OAuth (see Authentication below)

# 3. Build and start
docker compose up -d --build
```

## Authentication

### OAuth login (recommended)

Uses your Pro/Max subscription — no API key needed. Run this once after the first build:

```bash
docker exec -it claude-box claude
```

Claude Code will print a URL since no browser is available inside the container. Open that URL on any device with a browser (your laptop, phone, etc.), sign in, and the token flows back to the CLI. The credential is saved to `~/.claude/.credentials.json` inside the mounted volume, so it persists across container restarts.

If the token expires, just repeat the step above.

### API key (optional)

If you prefer Console API billing, set `ANTHROPIC_API_KEY` in your `.env` file. When set, it takes precedence over OAuth.

## Usage

### Interactive session

```bash
docker exec -it claude-box bash
claude
```

### Headless one-shot

```bash
docker exec claude-box claude -p "Explain what this project does" --output-format json
```

### Run against a specific project

Place or clone projects into the `./workspace` directory on the host — they appear at `/workspace` inside the container.

```bash
docker exec -w /workspace/my-project claude-box claude -p "Find bugs in this codebase"
```

### Remote control

[Remote control](https://docs.anthropic.com/en/docs/claude-code/remote-control) lets you steer a Claude Code session running inside the container from any device — your phone, tablet, or another machine's browser. The session keeps full access to the container's filesystem, tools, and MCP servers; the remote device is just an interface.

```bash
# Start a remote-controllable session
docker exec -it claude-box claude remote-control --name "my-project"
```

This prints a URL and QR code. Open the URL on any device to send prompts and see results in real time while Claude Code runs locally in the container.

Since the container is always-on, this pairs well with a long-running session you can pick up from anywhere — start a task from your desk, check on it from your phone, or hand it off to a colleague.

Useful flags:

| Flag | Purpose |
|---|---|
| `--name "My Project"` | Custom session title |
| `--spawn <mode>` | How concurrent sessions work: `same-dir` (default) or `worktree` |
| `--capacity <N>` | Max concurrent sessions (default: 32) |

## Volumes

| Host path | Container path | Purpose |
|---|---|---|
| `./data/claude` | `/home/claude/.claude` | OAuth tokens, settings, conversation history, config |
| `./workspace` | `/workspace` | Project files Claude Code operates on |

`~/.claude.json` is symlinked into the mounted volume automatically, so all Claude Code state persists with a single mount.

Both directories are created automatically. `data/` and `workspace/` are git-ignored.

## Playwright

Google Chrome and the [Playwright MCP server](https://github.com/microsoft/playwright-mcp) are included out of the box. Claude Code can use browser automation tools without any additional setup.

The container is configured with `shm_size: 2g`, `SYS_ADMIN`, and `SYS_PTRACE` capabilities to support headless Chrome.

## MCP servers

MCP servers are registered in [`entrypoint.sh`](entrypoint.sh) on every container startup using `claude mcp add`. To add your own, append a line:

```bash
claude mcp add --scope user my-server -- npx -y @my/mcp-server@latest 2>/dev/null || true
```