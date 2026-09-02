#!/usr/bin/env bash
# Configure KDE Plasma (KWin virtual desktops, shortcuts, window rules)
# 100% home directory confined — safe for multi-user shared machines.
set -euo pipefail

KDE_CONFIG_DIR="$HOME/.config"
KWRITE_CMD=""

if command -v kwriteconfig6 >/dev/null 2>&1; then
    KWRITE_CMD="kwriteconfig6"
elif command -v kwriteconfig5 >/dev/null 2>&1; then
    KWRITE_CMD="kwriteconfig5"
fi

set_kconfig() {
    local file="$1"
    local group="$2"
    local key="$3"
    local val="$4"

    if [[ -n "$KWRITE_CMD" ]]; then
        "$KWRITE_CMD" --file "$file" --group "$group" --key "$key" "$val"
    else
        # Fallback INI writer if kwriteconfig is not in PATH
        mkdir -p "$(dirname "$file")"
        touch "$file"
        if grep -q "^\[$group\]" "$file" 2>/dev/null; then
            if grep -q "^$key=" "$file" 2>/dev/null; then
                sed -i "/^\[$group\]/,/^\[/ s|^$key=.*|$key=$val|" "$file"
            else
                sed -i "/^\[$group\]/a $key=$val" "$file"
            fi
        else
            printf "\n[%s]\n%s=%s\n" "$group" "$key" "$val" >> "$file"
        fi
    fi
}

echo "==> Configuring KDE Virtual Desktops (1D Filmstrip)..."
KWINRC="$KDE_CONFIG_DIR/kwinrc"
set_kconfig "$KWINRC" "Desktops" "Number" "10"
set_kconfig "$KWINRC" "Desktops" "Rows" "1"
set_kconfig "$KWINRC" "Plugins" "slideEnabled" "true"

echo "==> Configuring KDE SNXZ Accent Color (#7186fd)..."
KDEGLOBALS="$KDE_CONFIG_DIR/kdeglobals"
set_kconfig "$KDEGLOBALS" "General" "AccentColor" "113,134,253"
set_kconfig "$KDEGLOBALS" "General" "accentColorFromWallpaper" "false"
set_kconfig "$KDEGLOBALS" "General" "ColorScheme" "BreezeDark"

echo "==> Configuring KDE Global Shortcuts & KWin Rules..."
SHORTCUTSRC="$KDE_CONFIG_DIR/kglobalshortcutsrc"

# KWin Window Management Shortcuts
set_kconfig "$SHORTCUTSRC" "kwin" "Window Close" "Meta+Q\tAlt+F4,Alt+F4,Close Window"
set_kconfig "$SHORTCUTSRC" "kwin" "Switch to Next Desktop" "Meta+Right,none,Switch to Next Desktop"
set_kconfig "$SHORTCUTSRC" "kwin" "Switch to Previous Desktop" "Meta+Left,none,Switch to Previous Desktop"
set_kconfig "$SHORTCUTSRC" "kwin" "Window to Next Desktop" "Meta+Shift+Right,none,Window to Next Desktop"
set_kconfig "$SHORTCUTSRC" "kwin" "Window to Previous Desktop" "Meta+Shift+Left,none,Window to Previous Desktop"

for i in {1..9}; do
    set_kconfig "$SHORTCUTSRC" "kwin" "Switch to Desktop $i" "Meta+$i,none,Switch to Desktop $i"
    set_kconfig "$SHORTCUTSRC" "kwin" "Window to Desktop $i" "Meta+Shift+$i,none,Window to Desktop $i"
done

# Custom Application Shortcuts
set_kconfig "$SHORTCUTSRC" "herdr-sessionizer.desktop" "_launch" "Meta+\\,none,Herdr Sessionizer"
set_kconfig "$SHORTCUTSRC" "herdr-dual.desktop" "_launch" "Meta+Alt+\\,none,Herdr Dual"
set_kconfig "$SHORTCUTSRC" "tmux-sessionizer.desktop" "_launch" "Meta+Shift+\\,none,Tmux Sessionizer"
set_kconfig "$SHORTCUTSRC" "herdr.desktop" "_launch" "Meta+Alt+Return,none,Herdr Terminal"
set_kconfig "$SHORTCUTSRC" "obsidian.desktop" "_launch" "Meta+Shift+O,none,Obsidian"

# Refresh desktop system configuration cache
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
elif command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 --noincremental >/dev/null 2>&1 || true
fi

# Reload KWin configuration if running
if [[ -n "${DISPLAY:-}" ]]; then
    if command -v qdbus >/dev/null 2>&1; then
        qdbus org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi
fi

echo "  ✓ KDE Plasma virtual desktops & shortcuts configured."
