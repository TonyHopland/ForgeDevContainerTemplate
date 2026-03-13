#!/bin/bash
set -e

echo "Installing Beads for user $_REMOTE_USER..."

# Run the installer as the primary user
su - $_REMOTE_USER -c "curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash"

echo "Beads installed successfully"


