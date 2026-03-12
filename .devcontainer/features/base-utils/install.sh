#!/bin/bash
set -e

echo "Installing base utilities..."
apt-get update
apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    jq \
    golang \
    sqlite3 \
    gh \
    && rm -rf /var/lib/apt/lists/*

# Detect the primary non-root user (usually the first user in /home)
PRIMARY_USER=""
if [ -d "/home" ]; then
    PRIMARY_USER=$(ls -1 /home 2>/dev/null | head -n 1)
fi

if [ -z "$PRIMARY_USER" ]; then
    echo "Warning: No user found in /home, Go paths may not be set correctly"
else
    # Set up Go paths for the primary user
    mkdir -p /home/$PRIMARY_USER/go
    chown -R $PRIMARY_USER:$PRIMARY_USER /home/$PRIMARY_USER/go

    # Create system-wide profile.d script for PATH
    cat > /etc/profile.d/devcontainer-tools.sh << EOF
export GOPATH=/home/$PRIMARY_USER/go
export PATH=\$PATH:\$GOPATH/bin
EOF

    chmod +x /etc/profile.d/devcontainer-tools.sh
fi

echo "Base utilities installed successfully"
