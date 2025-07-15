#!/bin/bash

set -e

# Constants
INSTALL_DIR="/usr/local/bin"
TEMP_DIR="$(mktemp -d)"

# Prerequisites
if ! command -v unzip &>/dev/null; then
    echo "🔧 'unzip' not found. Installing..."
    sudo apt update && sudo apt install -y unzip
fi

if ! command -v curl &>/dev/null; then
    echo "🔧 'curl' not found. Installing..."
    sudo apt update && sudo apt install -y curl
fi

# Get latest version from GitHub API
echo "📡 Fetching latest OpenTofu release..."
LATEST_JSON=$(curl -s https://api.github.com/repos/opentofu/opentofu/releases/latest)
TOFU_VERSION=$(echo "$LATEST_JSON" | grep -oP '"tag_name":\s*"\K[^"]+')

# Sanitize version
TOFU_VERSION="${TOFU_VERSION#v}"  # remove leading 'v'

# Build download URL
ARCH="linux_amd64"
TOFU_ZIP="tofu_${TOFU_VERSION}_${ARCH}.zip"
DOWNLOAD_URL="https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/${TOFU_ZIP}"

echo "⬇️ Downloading Tofu v$TOFU_VERSION..."
cd "$TEMP_DIR"
curl -LO "$DOWNLOAD_URL"

echo "📦 Extracting..."
unzip -o "$TOFU_ZIP"

echo "🚚 Installing to $INSTALL_DIR..."
sudo mv tofu "$INSTALL_DIR/"

echo "🧹 Cleaning up..."
cd ~
rm -rf "$TEMP_DIR"

echo "✅ Installation complete:"
tofu version
