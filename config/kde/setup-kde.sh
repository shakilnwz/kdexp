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

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "==> Configuring KDE Dynamic Virtual Desktops (GNOME-style)..."
KWIN_SCRIPTS_DIR="$HOME/.local/share/kwin/scripts"
mkdir -p "$KWIN_SCRIPTS_DIR"

if [[ -d "$DOTFILES/config/kde/kwin-scripts/dynamic_workspaces" ]]; then
    # Clean up legacy symlink if present so script can be installed as concrete directory
    if [[ -L "$KWIN_SCRIPTS_DIR/dynamic_workspaces" ]]; then
        rm -f "$KWIN_SCRIPTS_DIR/dynamic_workspaces"
    fi

    # Install as concrete directory
    mkdir -p "$KWIN_SCRIPTS_DIR/dynamic_workspaces"
    cp -rf "$DOTFILES/config/kde/kwin-scripts/dynamic_workspaces/." "$KWIN_SCRIPTS_DIR/dynamic_workspaces/"
    echo "  ✓ Installed dynamic_workspaces script to $KWIN_SCRIPTS_DIR/dynamic_workspaces"
    
    # Register with KPackage tool if available
    if command -v kpackagetool6 >/dev/null 2>&1; then
        kpackagetool6 --type KWin/Script -r dynamic_workspaces >/dev/null 2>&1 || true
        kpackagetool6 --type KWin/Script -i "$KWIN_SCRIPTS_DIR/dynamic_workspaces" >/dev/null 2>&1 || true
    elif command -v kpackagetool5 >/dev/null 2>&1; then
        kpackagetool5 --type KWin/Script -r dynamic_workspaces >/dev/null 2>&1 || true
        kpackagetool5 --type KWin/Script -i "$KWIN_SCRIPTS_DIR/dynamic_workspaces" >/dev/null 2>&1 || true
    fi
fi

KWINRC="$KDE_CONFIG_DIR/kwinrc"
set_kconfig "$KWINRC" "Desktops" "Number" "2"
set_kconfig "$KWINRC" "Desktops" "Rows" "1"
set_kconfig "$KWINRC" "Plugins" "slideEnabled" "true"
set_kconfig "$KWINRC" "Plugins" "dynamic_workspacesEnabled" "true"

echo "==> Configuring KDE SNXZ Accent Color (#7186fd)..."
KDEGLOBALS="$KDE_CONFIG_DIR/kdeglobals"
set_kconfig "$KDEGLOBALS" "General" "AccentColor" "113,134,253"
set_kconfig "$KDEGLOBALS" "General" "accentColorFromWallpaper" "false"
set_kconfig "$KDEGLOBALS" "General" "ColorScheme" "BreezeDark"

echo "==> Configuring KDE Keyboard (Caps Lock -> Control modifier)..."
KXKBRC="$KDE_CONFIG_DIR/kxkbrc"
set_kconfig "$KXKBRC" "Layout" "Options" "caps:ctrl_modifier"
set_kconfig "$KXKBRC" "Layout" "ResetOldOptions" "true"

KCMINPUTRC="$KDE_CONFIG_DIR/kcminputrc"
set_kconfig "$KCMINPUTRC" "Keyboard" "XkbOptions" "caps:ctrl_modifier"

echo "==> Configuring KDE SNXZ Default Wallpaper (1-abstract.jpg)..."
WALLPAPER_DIR="$HOME/.local/share/wallpapers/kdexp"
DEFAULT_WALLPAPER="$WALLPAPER_DIR/1-abstract.jpg"
mkdir -p "$HOME/.local/share/wallpapers"

if [[ -d "$DOTFILES/config/kde/wallpapers" ]]; then
    ln -nsf "$DOTFILES/config/kde/wallpapers" "$WALLPAPER_DIR"
    echo "  ✓ Linked wallpapers to $WALLPAPER_DIR"
fi

if [[ -f "$DEFAULT_WALLPAPER" ]]; then
    # 1. Apply wallpaper via plasma-apply-wallpaperimage if available
    if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
        plasma-apply-wallpaperimage "$DEFAULT_WALLPAPER" >/dev/null 2>&1 || true
    fi

    # 2. Apply wallpaper via D-Bus if plasmashell is running (Plasma 6 / 5)
    QDBUS_CMD=""
    if command -v qdbus6 >/dev/null 2>&1; then
        QDBUS_CMD="qdbus6"
    elif command -v qdbus >/dev/null 2>&1; then
        QDBUS_CMD="qdbus"
    fi

    if [[ -n "$QDBUS_CMD" && (-n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}") ]]; then
        "$QDBUS_CMD" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
            var allDesktops = desktops();
            for (var i = 0; i < allDesktops.length; i++) {
                var d = allDesktops[i];
                d.wallpaperPlugin = 'org.kde.image';
                d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
                d.writeConfig('Image', 'file://$DEFAULT_WALLPAPER');
            }
        " >/dev/null 2>&1 || true
    fi

    # 3. Configure Lock Screen wallpaper (kscreenlockerrc)
    KSCREENLOCKERRC="$KDE_CONFIG_DIR/kscreenlockerrc"
    set_kconfig "$KSCREENLOCKERRC" "Greeter" "WallpaperPlugin" "org.kde.image"
    set_kconfig "$KSCREENLOCKERRC" "Greeter][Wallpaper][org.kde.image][General" "Image" "file://$DEFAULT_WALLPAPER"

    # 4. Configure Plasma desktop applet containment if config exists
    PLASMA_APPLETRC="$KDE_CONFIG_DIR/plasma-org.kde.plasma.desktop-appletsrc"
    if [[ -f "$PLASMA_APPLETRC" ]]; then
        sed -i -E "s|^Image=.*|Image=file://$DEFAULT_WALLPAPER|" "$PLASMA_APPLETRC" 2>/dev/null || true
    fi
    echo "  ✓ Configured default wallpaper: 1-abstract.jpg"
fi

echo "==> Configuring KDE Global Shortcuts & KWin Rules..."
SHORTCUTSRC="$KDE_CONFIG_DIR/kglobalshortcutsrc"

# KWin Window Management Shortcuts
set_kconfig "$SHORTCUTSRC" "kwin" "Window Close" $'Meta+Q\tAlt+F4,Alt+F4,Close Window'
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

# Reload KWin configuration if running (Wayland or X11)
if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    elif command -v qdbus >/dev/null 2>&1; then
        qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || qdbus org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi
fi

# Apply Caps Lock remap if session is active
if [[ -x "$HOME/.local/bin/remap-caps" ]]; then
    "$HOME/.local/bin/remap-caps" >/dev/null 2>&1 || true
fi

# Link and initialize xbindkeys configuration for Meta + Mouse Wheel navigation
if [[ -f "$DOTFILES/config/xbindkeys/config" ]]; then
    mkdir -p "$HOME/.config/xbindkeys"
    ln -nsf "$DOTFILES/config/xbindkeys/config" "$HOME/.config/xbindkeys/config"
    if command -v xbindkeys >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
        pkill -x xbindkeys 2>/dev/null || true
        xbindkeys -f "$HOME/.config/xbindkeys/config" 2>/dev/null || true
    fi
fi

echo "  ✓ KDE Plasma virtual desktops & shortcuts configured."
