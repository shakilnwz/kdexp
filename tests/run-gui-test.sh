#!/usr/bin/env bash
# Build and run the KDE Plasma GUI test environment via Docker Compose
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

mkdir -p "$ROOT_DIR/data/test-home"

echo "==> Starting kdexp GUI test environment via Docker Compose..."
cd "$ROOT_DIR"
docker compose up --build "$@"

