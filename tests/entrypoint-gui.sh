#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up test environment..."
mkdir -p /home/testuser/.kdexp
if [[ -d /home/testuser/dotfiles ]]; then
    cp -r /home/testuser/dotfiles/. /home/testuser/.kdexp/
fi

export DISPLAY=:1
export XDG_RUNTIME_DIR="/tmp/runtime-testuser"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

echo "==> Starting virtual display (Xvfb 1920x1080)..."
Xvfb :1 -screen 0 1920x1080x24 +extension GLX +extension RANDR +render -noreset &
sleep 1

echo "==> Starting x11vnc..."
x11vnc -display :1 -nopw -listen localhost -xkb -forever -shared >/dev/null 2>&1 &

echo "==> Starting noVNC web server on port 6080..."
websockify --web=/usr/share/novnc/ 6080 localhost:5900 >/dev/null 2>&1 &

echo ""
echo "=================================================================="
echo "  🚀 KDE Plasma Desktop is now running inside Docker!"
echo "  👉 Open in your web browser: http://localhost:6080/vnc.html"
echo ""
echo "  Inside the desktop:"
echo "    1. Open Konsole terminal"
echo "    2. Run: cd ~/.kdexp && ./bootstrap.sh"
echo "    3. Test your shortcuts, KWin rules, and shell"
echo "=================================================================="
echo ""

# Start KDE Plasma session with D-Bus
exec dbus-run-session startplasma-x11
