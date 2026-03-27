FROM debian:bookworm-slim

ARG NODE_MAJOR=22

# System packages + Node.js LTS + Python 3 — single layer, clean cache
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        git \
        ripgrep \
        jq \
        openssh-client \
        python3 \
        python3-pip \
        python3-venv \
        gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list >/dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs gh && \
    apt-get purge -y gnupg && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Non-root user
RUN groupadd -r claude && \
    useradd -r -g claude -m -s /bin/bash claude

# Install Google Chrome (needs root) — this is what @playwright/mcp expects by default
RUN npx playwright install --with-deps chrome && \
    rm -rf /var/lib/apt/lists/* /root/.cache /root/.npm

# Create workspace
RUN mkdir -p /workspace && chown claude:claude /workspace

# Switch to non-root user for remaining installs
USER claude

# Install Claude Code CLI (native installer)
RUN curl -fsSL https://claude.ai/install.sh | bash

ENV PATH="/home/claude/.local/bin:${PATH}"

# Ensure ~/.claude exists with correct ownership
RUN mkdir -p /home/claude/.claude

# Entrypoint fixes permissions and registers MCP servers on every startup
# Runs as root at startup, then drops to claude user
USER root
COPY entrypoint.sh /home/claude/entrypoint.sh
RUN chmod +x /home/claude/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/home/claude/entrypoint.sh"]
CMD ["sleep", "infinity"]
