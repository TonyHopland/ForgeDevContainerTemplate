#!/bin/bash
set -e

# Detect the primary non-root user (usually the first user in /home)
PRIMARY_USER=""
if [ -d "/home" ]; then
    PRIMARY_USER=$(ls -1 /home 2>/dev/null | head -n 1)
fi

if [ -z "$PRIMARY_USER" ]; then
    echo "Error: No user found in /home, cannot install Claude Code"
    exit 1
fi

echo "Installing Claude Code for user $PRIMARY_USER..."

# Run the installer as the primary user to install in their home directory
su - $PRIMARY_USER -c "curl -fsSL https://claude.ai/install.sh | bash"

echo "Claude Code installed successfully"
