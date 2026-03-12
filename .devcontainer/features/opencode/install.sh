#!/bin/bash
set -e

# Detect the primary non-root user (usually the first user in /home)
PRIMARY_USER=""
if [ -d "/home" ]; then
    PRIMARY_USER=$(ls -1 /home 2>/dev/null | head -n 1)
fi

if [ -z "$PRIMARY_USER" ]; then
    echo "Error: No user found in /home, cannot install OpenCode"
    exit 1
fi

echo "Installing OpenCode for user $PRIMARY_USER..."

# Run the installer as the primary user
su - $PRIMARY_USER -c "curl -fsSL https://opencode.ai/install | bash"

echo "OpenCode installed successfully"
