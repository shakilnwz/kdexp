#!/usr/bin/env bash
# Build and run the KDE Plasma GUI test environment in Docker with noVNC
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Building kdexp KDE Plasma GUI test image..."
docker build -t kdexp-gui-test -f "$SCRIPT_DIR/Dockerfile.gui" "$ROOT_DIR"

echo "==> Starting kdexp GUI test container on port 6080..."
docker run --rm -it \
    -p 6080:6080 \
    -v "$ROOT_DIR:/home/testuser/dotfiles:ro" \
    kdexp-gui-test
