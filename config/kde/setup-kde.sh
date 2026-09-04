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

echo "==> Configuring Karousel Scrolling Window Manager & Slide Animations..."
KWIN_SCRIPTS_DIR="$HOME/.local/share/kwin/scripts"
KWIN_EFFECTS_DIR="$HOME/.local/share/kwin/effects"
mkdir -p "$KWIN_SCRIPTS_DIR" "$KWIN_EFFECTS_DIR"

# Clean up legacy dynamic_workspaces if present
rm -rf "$KWIN_SCRIPTS_DIR/dynamic_workspaces"

if [[ -d "$DOTFILES/config/kde/kwin-scripts/karousel" ]]; then
    ln -nsf "$DOTFILES/config/kde/kwin-scripts/karousel" "$KWIN_SCRIPTS_DIR/karousel"
    echo "  ✓ Linked Karousel script to $KWIN_SCRIPTS_DIR/karousel"

    if command -v kpackagetool6 >/dev/null 2>&1; then
        kpackagetool6 --type KWin/Script -u "$KWIN_SCRIPTS_DIR/karousel" >/dev/null 2>&1 || \
        kpackagetool6 --type KWin/Script -i "$KWIN_SCRIPTS_DIR/karousel" >/dev/null 2>&1 || true
    fi
fi

if [[ -d "$DOTFILES/config/kde/kwin-effects/kwin4_effect_geometry_change" ]]; then
    ln -nsf "$DOTFILES/config/kde/kwin-effects/kwin4_effect_geometry_change" "$KWIN_EFFECTS_DIR/kwin4_effect_geometry_change"
    echo "  ✓ Linked Geometry Change effect to $KWIN_EFFECTS_DIR/kwin4_effect_geometry_change"

    if command -v kpackagetool6 >/dev/null 2>&1; then
        kpackagetool6 --type KWin/Effect -u "$KWIN_EFFECTS_DIR/kwin4_effect_geometry_change" >/dev/null 2>&1 || \
        kpackagetool6 --type KWin/Effect -i "$KWIN_EFFECTS_DIR/kwin4_effect_geometry_change" >/dev/null 2>&1 || true
    fi
fi

KWINRC="$KDE_CONFIG_DIR/kwinrc"
# Single virtual desktop for continuous horizontal carousel
set_kconfig "$KWINRC" "Desktops" "Number" "1"
set_kconfig "$KWINRC" "Desktops" "Rows" "1"

# Enable Karousel and Slide Animation plugins
set_kconfig "$KWINRC" "Plugins" "karouselEnabled" "true"
set_kconfig "$KWINRC" "Plugins" "kwin4_effect_geometry_changeEnabled" "true"
set_kconfig "$KWINRC" "Plugins" "dynamic_workspacesEnabled" "false"

# Configure Karousel: 100% full-width presets, 0 outer gaps, 8px inner gap, centered scrolling
set_kconfig "$KWINRC" "Script-karousel" "presetWidths" "100%"
set_kconfig "$KWINRC" "Script-karousel" "gapsOuterTop" "0"
set_kconfig "$KWINRC" "Script-karousel" "gapsOuterBottom" "0"
set_kconfig "$KWINRC" "Script-karousel" "gapsOuterLeft" "0"
set_kconfig "$KWINRC" "Script-karousel" "gapsOuterRight" "0"
set_kconfig "$KWINRC" "Script-karousel" "gapsInnerHorizontal" "8"
set_kconfig "$KWINRC" "Script-karousel" "gapsInnerVertical" "0"
set_kconfig "$KWINRC" "Script-karousel" "scrollingCentered" "true"
set_kconfig "$KWINRC" "Script-karousel" "scrollingLazy" "false"

# Configure Geometry Change animation duration (250ms smooth slide)
set_kconfig "$KWINRC" "Effect-kwin4_effect_geometry_change" "Duration" "250"

echo "==> Configuring KDE SNXZ Accent Color (#7186fd)..."
KDEGLOBALS="$KDE_CONFIG_DIR/kdeglobals"
set_kconfig "$KDEGLOBALS" "General" "AccentColor" "113,134,253"
set_kconfig "$KDEGLOBALS" "General" "accentColorFromWallpaper" "false"
set_kconfig "$KDEGLOBALS" "General" "ColorScheme" "BreezeDark"

echo "==> Configuring KDE Keyboard (Caps Lock -> Control modifier)..."
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
set_kconfig "$SHORTCUTSRC" "kwin" "Window Close" "Meta+Q\tAlt+F4,Alt+F4,Close Window"

# Karousel Carousel Navigation & Window Movement
set_kconfig "$SHORTCUTSRC" "kwin" "focus-left" "Meta+Left\tMeta+A,Meta+Left,Move focus left"
set_kconfig "$SHORTCUTSRC" "kwin" "focus-right" "Meta+Right\tMeta+D,Meta+Right,Move focus right"
set_kconfig "$SHORTCUTSRC" "kwin" "column-move-left" "Meta+Shift+Left,Meta+Shift+Left,Move column left"
set_kconfig "$SHORTCUTSRC" "kwin" "column-move-right" "Meta+Shift+Right,Meta+Shift+Right,Move column right"
set_kconfig "$SHORTCUTSRC" "kwin" "window-toggle-floating" "Meta+Space,Meta+Space,Toggle floating"
set_kconfig "$SHORTCUTSRC" "kwin" "cycle-preset-widths" "Meta+R,Meta+R,Cycle through preset column widths"

# Clear legacy virtual desktop switching shortcuts (now single-desktop carousel)
set_kconfig "$SHORTCUTSRC" "kwin" "Switch to Next Desktop" "none,none,Switch to Next Desktop"
set_kconfig "$SHORTCUTSRC" "kwin" "Switch to Previous Desktop" "none,none,Switch to Previous Desktop"
set_kconfig "$SHORTCUTSRC" "kwin" "Window to Next Desktop" "none,none,Window to Next Desktop"
set_kconfig "$SHORTCUTSRC" "kwin" "Window to Previous Desktop" "none,none,Window to Previous Desktop"

for i in {1..9}; do
    set_kconfig "$SHORTCUTSRC" "kwin" "Switch to Desktop $i" "none,none,Switch to Desktop $i"
    set_kconfig "$SHORTCUTSRC" "kwin" "Window to Desktop $i" "none,none,Window to Desktop $i"
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

echo "  ✓ KDE Plasma Karousel scrolling mode, slide animations & shortcuts configured."
