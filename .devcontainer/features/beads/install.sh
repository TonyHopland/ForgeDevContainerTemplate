#!/bin/bash
set -e

# Detect the primary non-root user (usually the first user in /home)
PRIMARY_USER=""
if [ -d "/home" ]; then
    PRIMARY_USER=$(ls -1 /home 2>/dev/null | head -n 1)
fi

if [ -z "$PRIMARY_USER" ]; then
    echo "Error: No user found in /home, cannot install Beads"
    exit 1
fi

echo "Installing Beads for user $PRIMARY_USER..."

# Add go/bin to PATH for the node user if not already present
if [ -n "$PRIMARY_USER" ] && [ "$PRIMARY_USER" = "node" ]; then
    # Add to .bashrc
    if ! grep -q '/home/node/go/bin' /home/node/.bashrc 2>/dev/null; then
        echo 'export PATH="$PATH:/home/node/go/bin"' >> /home/node/.bashrc
    fi
    # Add to .profile as well for login shells
    if ! grep -q '/home/node/go/bin' /home/node/.profile 2>/dev/null; then
        echo 'export PATH="$PATH:/home/node/go/bin"' >> /home/node/.profile
    fi
    # Also add to containerEnv in devcontainer.json
    if [ -f "/workspaces/ForgeDevContainerTemplate/.devcontainer/devcontainer.json" ]; then
        # Check if containerEnv already has PATH
        if ! grep -q 'PATH.*go/bin' "/workspaces/ForgeDevContainerTemplate/.devcontainer/devcontainer.json"; then
            # Add PATH to containerEnv
            sed -i 's/"containerEnv": {/"containerEnv": {\n    "PATH": "\/home\/node\/go:\/home\/node\/go\/bin",/' "/workspaces/ForgeDevContainerTemplate/.devcontainer/devcontainer.json"
        fi
    fi
fi

# Run the installer as the primary user
su - $PRIMARY_USER -c "curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash"

echo "Beads installed successfully"


