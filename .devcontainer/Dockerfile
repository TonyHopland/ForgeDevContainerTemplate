FROM mcr.microsoft.com/devcontainers/typescript-node

RUN wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list


# Install common utilities
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    jq \
    golang \
    sqlite3 \
    google-chrome-stable \
    gh \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------------------
# Install Dolt (Git for Data)
# https://github.com/dolthub/dolt
# -------------------------------------------------------------------
RUN curl -L https://github.com/dolthub/dolt/releases/latest/download/install.sh | bash

# -------------------------------------------------------------------
# Install Beads (bd) - distributed issue tracker for AI agents
# https://github.com/steveyegge/beads
# -------------------------------------------------------------------
RUN curl -L https://github.com/steveyegge/beads/releases/download/v0.59.0/beads_0.59.0_linux_amd64.tar.gz | tar xz -C /usr/local/bin

# -------------------------------------------------------------------
# Install OpenCode - open source AI coding agent
# https://github.com/anomalyco/opencode
# -------------------------------------------------------------------
RUN curl -fsSL https://opencode.ai/install | bash \
    && cp /root/.opencode/bin/opencode /usr/local/bin/opencode \
    && chmod 755 /usr/local/bin/opencode

# -------------------------------------------------------------------
# Install Anthropic CLI (ClaudeCode)
# https://github.com/anthropics/anthropic-sdk-python
# -------------------------------------------------------------------
RUN npm install -g @anthropic-ai/claude-code

# -------------------------------------------------------------------
# Install Forge — download the latest release from GitHub
# https://github.com/Robin831/Forge
# -------------------------------------------------------------------
RUN curl -fsSL https://raw.githubusercontent.com/Robin831/Forge/main/install.sh | bash && \
    cp /root/bin/forge /usr/local/bin/forge && \
    chmod 755 /usr/local/bin/forge

# Configure GOPATH and add it to PATH
ENV GOPATH=/home/node/go
ENV PATH=$PATH:$GOPATH/bin:/usr/local/go/bin

# Install govulncheck with proper GOPATH
RUN mkdir -p /home/node/go/bin && \
    go install golang.org/x/vuln/cmd/govulncheck@latest && \
    chmod -R 777 /home/node/go

# Verify installations
RUN git --version \
    && dolt version \
    && bd --version \
    && opencode --version \
    && forge --version \
    && claude-code --version || true \
    && google-chrome --version || true