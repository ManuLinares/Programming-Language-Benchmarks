#!/usr/bin/env bash
set -e

# Installer for CI
echo "Downloading C3..."
wget -q https://github.com/c3lang/c3c/releases/download/latest-prerelease-tag/c3-linux-static.tar.gz

echo "Unpacking C3..."
tar -xzf c3-linux-static.tar.gz
sudo mv c3 /usr/local/c3

# Add to system path
sudo ln -sf /usr/local/c3/c3c /usr/local/bin/c3c

# Verify installation
c3c --version
