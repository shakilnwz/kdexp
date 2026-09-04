#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up test environment..."

# Ensure /home/testuser is owned by testuser and has basic skel files
sudo chown -R testuser:testuser /home/testuser 2>/dev/null || true
if [[ ! -f /home/testuser/.bashrc && -d /etc/skel ]]; then
    echo "==> Initializing fresh home directory from /etc/skel..."
    cp -r /etc/skel/. /home/testuser/ 2>/dev/null || true
    sudo chown -R testuser:testuser /home/testuser 2>/dev/null || true
fi

mkdir -p /home/testuser/.kdexp
src_dir=""
if [[ -d /dotfiles ]]; then
    src_dir="/dotfiles"
elif [[ -d /home/testuser/dotfiles ]]; then
    src_dir="/home/testuser/dotfiles"
fi

if [[ -n "$src_dir" ]]; then
    for item in "$src_dir"/* "$src_dir"/.[!.]*; do
        [[ -e "$item" ]] || continue
        base=$(basename "$item")
        [[ "$base" == "data" ]] && continue
        cp -rf "$item" /home/testuser/.kdexp/
    done
fi

if [[ $# -gt 0 ]]; then
    exec "$@"
fi

export DISPLAY=:1
export XDG_RUNTIME_DIR="/tmp/runtime-testuser"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

sudo mkdir -p /tmp/.X11-unix 2>/dev/null || true
sudo chmod 1777 /tmp/.X11-unix 2>/dev/null || true

echo "==> Starting virtual display (Xvfb 1920x1080)..."
Xvfb :1 -screen 0 1920x1080x24 +extension GLX +extension RANDR +render -noreset &
sleep 1

echo "==> Starting x11vnc..."
x11vnc -display :1 -nopw -listen localhost -xkb -forever -shared >/dev/null 2>&1 &

echo "==> Starting noVNC web server on port 6080..."
websockify --web=/usr/share/novnc/ 6080 localhost:5900 >/dev/null 2>&1 &

# Disable KDE screen locker timeout in test environment
mkdir -p /home/testuser/.config
if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file /home/testuser/.config/kscreenlockerrc --group Daemon --key Autolock false 2>/dev/null || true
    kwriteconfig6 --file /home/testuser/.config/kscreenlockerrc --group Daemon --key LockOnResume false 2>/dev/null || true
    kwriteconfig6 --file /home/testuser/.config/kscreenlockerrc --group Daemon --key Timeout 0 2>/dev/null || true
fi

echo ""
echo "=================================================================="
echo "  🚀 KDE Plasma Desktop is now running inside Docker!"
echo "  👉 Open in your web browser: http://localhost:6080/vnc.html"
echo "  🔑 User: testuser | Password: kdexp"
echo ""
echo "  Inside the desktop:"
echo "    1. Open Konsole terminal"
echo "    2. Run: cd ~/.kdexp && ./bootstrap.sh"
echo "    3. Test your shortcuts, KWin rules, and shell"
echo "=================================================================="
echo ""

# Start KDE Plasma session with D-Bus
if command -v startplasma-x11 >/dev/null 2>&1; then
    exec dbus-run-session startplasma-x11
elif command -v startplasma-wayland >/dev/null 2>&1; then
    exec dbus-run-session startplasma-wayland
else
    kwin_x11 --replace &
    exec dbus-run-session plasmashell
fi
