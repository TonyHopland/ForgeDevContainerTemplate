#!/bin/bash
# Install The Forge — download the latest release from GitHub.
# Usage: curl -fsSL https://raw.githubusercontent.com/Robin831/Forge/main/install.sh | bash
#
# Or run locally: ./install.sh [--install-dir <path>] [--version <tag>]

set -euo pipefail

REPO="Robin831/Forge"
BINARY_NAME="forge"

# --- Helpers ----------------------------------------------------------------

write_step() { echo "=> $1" >&2; }
write_ok()   { echo "   $1" >&2; }
write_err()  { echo "ERROR: $1" >&2; exit 1; }
write_warn() { echo "   Warning: $1" >&2; }

# --- Detect OS/Arch ---------------------------------------------------------

write_step "Detecting platform..."

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="darwin"
else
    write_err "Unsupported OS: $OSTYPE (only Linux and macOS are supported)"
fi

# Detect architecture
if command -v uname &>/dev/null; then
    ARCH_RAW=$(uname -m)
else
    write_err "Cannot detect architecture: uname not found"
fi

case "$ARCH_RAW" in
    x86_64|amd64|AMD64)      ARCH="amd64" ;;
    aarch64|arm64|ARM64)     ARCH="arm64" ;;
    *) write_err "Unsupported architecture: $ARCH_RAW" ;;
esac

# macOS arm64 is fine; Windows arm64 was the only restriction in PS version
write_ok "$OS/$ARCH"

# --- Resolve install directory -----------------------------------------------

INSTALL_DIR="${INSTALL_DIR:-}"
if [[ -z "$INSTALL_DIR" ]]; then
    if [[ "$OS" == "windows" ]]; then
        INSTALL_DIR="$LOCALAPPDATA/Forge"
    else
        INSTALL_DIR="$HOME/bin"
    fi
fi

BINARY_PATH="$INSTALL_DIR/$BINARY_NAME"

# --- Resolve version ---------------------------------------------------------

write_step "Fetching latest release..."

VERSION="${VERSION:-}"
if [[ -n "$VERSION" ]]; then
    # Normalize: accept both "v1.2.3" and "1.2.3"
    if [[ "$VERSION" != v* ]]; then
        VERSION="v$VERSION"
    fi
    TAG="$VERSION"
    API_URL="https://api.github.com/repos/$REPO/releases/tags/$TAG"
else
    API_URL="https://api.github.com/repos/$REPO/releases/latest"
fi

# GitHub API rate limit handling - use curl with proper headers
RESPONSE=$(curl -fsSL -H "Accept: application/vnd.github+json" "$API_URL" 2>&1) || \
    write_err "Failed to fetch release from $API_URL"

TAG=$(echo "$RESPONSE" | jq -r '.tag_name' 2>/dev/null) || \
    write_err "Failed to parse response: could not extract tag_name"

RELEASE_VERSION="${TAG#v}"

write_ok "$TAG"

# --- Check if already installed at this version ------------------------------

if [[ -f "$BINARY_PATH" ]]; then
    write_step "Checking installed version..."
    CURRENT_VERSION=$("$BINARY_PATH" version 2>&1 | head -n1) || true
    if echo "$CURRENT_VERSION" | grep -qF "$RELEASE_VERSION"; then
        write_ok "Already on $TAG — nothing to do."
        exit 0
    fi
    write_ok "Installed: $CURRENT_VERSION -> upgrading to $TAG"
fi

# --- Build asset name --------------------------------------------------------

ASSET_NAME="${BINARY_NAME}_${RELEASE_VERSION}_${OS}_${ARCH}.zip"
CHECKSUM_ASSET_NAME="checksums.txt"

# Extract asset URLs from JSON response
ASSET_URL=$(echo "$RESPONSE" | jq -r ".assets[] | select(.name == \"$ASSET_NAME\") | .browser_download_url" 2>/dev/null) || \
    write_err "Failed to parse assets from release response"

CHECKSUM_URL=$(echo "$RESPONSE" | jq -r ".assets[] | select(.name == \"$CHECKSUM_ASSET_NAME\") | .browser_download_url" 2>/dev/null) || true

if [[ -z "$ASSET_URL" ]]; then
    AVAILABLE=$(echo "$RESPONSE" | jq -r '.assets[].name' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
    write_err "Asset '$ASSET_NAME' not found in release $TAG. Available: $AVAILABLE"
fi

# --- Download ----------------------------------------------------------------

TEMP_DIR=$(mktemp -d)
ZIP_PATH="$TEMP_DIR/$ASSET_NAME"
CHECKSUM_PATH="$TEMP_DIR/$CHECKSUM_ASSET_NAME"

cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

write_step "Downloading $ASSET_NAME..."
curl -fsSL -o "$ZIP_PATH" "$ASSET_URL" || write_err "Failed to download $ASSET_URL"
write_ok "Downloaded."

# --- Verify checksum ---------------------------------------------------------

if [[ -n "$CHECKSUM_URL" ]]; then
    write_step "Verifying checksum..."
    curl -fsSL -o "$CHECKSUM_PATH" "$CHECKSUM_URL" || \
        write_warn "Failed to download checksum file — skipping verification"

    ACTUAL_HASH=$(sha256sum "$ZIP_PATH" | awk '{print $1}')
    ESCAPED_NAME=$(printf '%s' "$ASSET_NAME" | sed 's/[[\.*^$()+?{|]/\\&/g')

    # Find the line matching our asset name (checksums.txt format: hash  filename)
    MATCHING_LINES=$(grep -E "${ESCAPED_NAME}$" "$CHECKSUM_PATH" 2>/dev/null || true)

    if [[ -n "$MATCHING_LINES" ]]; then
        LINE_COUNT=$(echo "$MATCHING_LINES" | wc -l)
        EXPECTED_HASH=$(echo "$MATCHING_LINES" | head -n1 | awk '{print $1}')

        if [[ "$LINE_COUNT" -eq 1 ]]; then
            if [[ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]]; then
                write_err "Checksum mismatch!\n  Expected: $EXPECTED_HASH\n  Actual:   $ACTUAL_HASH"
            fi
            write_ok "SHA256 verified."
        else
            write_err "Multiple checksum entries found for $ASSET_NAME — cannot verify uniquely."
        fi
    else
        write_warn "no checksum entry for $ASSET_NAME in checksums.txt — skipping verification."
    fi
else
    write_warn "checksums.txt not found in release — skipping verification."
fi

# --- Extract --------------------------------------------------------------

write_step "Extracting to $INSTALL_DIR..."
if [[ ! -d "$INSTALL_DIR" ]]; then
    mkdir -p "$INSTALL_DIR" || write_err "Failed to create directory: $INSTALL_DIR"
fi

EXTRACT_DIR="$TEMP_DIR/extracted"
mkdir -p "$EXTRACT_DIR"
unzip -q "$ZIP_PATH" -d "$EXTRACT_DIR" || write_err "Failed to extract archive"

# GoReleaser puts the binary at the root of the zip.
EXTRACTED_BINARY=$(find "$EXTRACT_DIR" -maxdepth 1 -type f -name "$BINARY_NAME*" | head -n1)

if [[ -z "$EXTRACTED_BINARY" ]]; then
    write_err "Could not find '$BINARY_NAME' binary inside the archive."
fi

cp -f "$EXTRACTED_BINARY" "$BINARY_PATH" || write_err "Failed to copy binary to $BINARY_PATH"

# Ensure the forge binary is executable on Unix-like systems.
chmod +x "$BINARY_PATH"

write_ok "Installed to $BINARY_PATH"

# --- Add to PATH -----------------------------------------------------------

# On Linux/macOS, ~/bin is often already in PATH. Just advise if not.
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    write_warn "Note: add '$INSTALL_DIR' to your PATH:"
    write_warn "  export PATH=\"$INSTALL_DIR:\$PATH\""
fi

# --- Print version ---------------------------------------------------------

write_step "Verifying installation..."
INSTALLED_VERSION=$("$BINARY_PATH" version 2>&1 | head -n1) || true
if [[ -n "$INSTALLED_VERSION" ]]; then
    write_ok "$INSTALLED_VERSION"
else
    write_ok "Installed $Tag (could not run 'forge version' — you may need to restart your terminal)."
fi

echo ""
write_ok "Forge $TAG installed successfully!"
write_warn "Run 'forge doctor' to check your setup."
