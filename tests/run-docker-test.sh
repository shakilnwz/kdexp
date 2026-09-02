#!/usr/bin/env bash
# Build and run kdexp test environment in Docker
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Building kdexp Ubuntu test image..."
docker build -t kdexp-test -f "$SCRIPT_DIR/Dockerfile" "$ROOT_DIR"

echo "==> Starting kdexp test container..."
docker run --rm -it \
    -v "$ROOT_DIR:/home/testuser/dotfiles:ro" \
    -w "/home/testuser" \
    kdexp-test \
    bash -c '
        echo "==> Copying dotfiles to simulate fresh git clone into ~/.kdexp..."
        cp -r /home/testuser/dotfiles /home/testuser/.kdexp
        cd /home/testuser/.kdexp
        ./bootstrap.sh
        echo "==> Testing shell environment..."
        source ~/.bashrc
        echo "==> Verifying aliases and PATH..."
        alias
        echo "PATH: $PATH"
        echo "==> Starting interactive subshell in test container (press Ctrl+D to exit):"
        bash
    '
