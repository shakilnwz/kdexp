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
    karousel_src="$DOTFILES/config/kde/kwin-scripts/karousel"
    karousel_dst="$KWIN_SCRIPTS_DIR/karousel"

    # Remove any broken or legacy symlink before installing
    if [[ -L "$karousel_dst" ]]; then
        rm -f "$karousel_dst"
    fi

    installed=false
    if command -v kpackagetool6 >/dev/null 2>&1; then
        if kpackagetool6 --type KWin/Script -u "$karousel_src" >/dev/null 2>&1 || \
           kpackagetool6 --type KWin/Script -i "$karousel_src" >/dev/null 2>&1; then
            installed=true
        fi
    fi

    # Fallback: install as concrete directory if kpackagetool6 is not available or failed
    if [[ "$installed" != true ]]; then
        rm -rf "$karousel_dst"
        cp -rf "$karousel_src" "$karousel_dst"
    fi
    echo "  ✓ Installed Karousel script to $karousel_dst"
fi

if [[ -d "$DOTFILES/config/kde/kwin-effects/kwin4_effect_geometry_change" ]]; then
    effect_src="$DOTFILES/config/kde/kwin-effects/kwin4_effect_geometry_change"
    effect_dst="$KWIN_EFFECTS_DIR/kwin4_effect_geometry_change"

    if [[ -L "$effect_dst" ]]; then
        rm -f "$effect_dst"
    fi

    installed=false
    if command -v kpackagetool6 >/dev/null 2>&1; then
        if kpackagetool6 --type KWin/Effect -u "$effect_src" >/dev/null 2>&1 || \
           kpackagetool6 --type KWin/Effect -i "$effect_src" >/dev/null 2>&1; then
            installed=true
        fi
    fi

    if [[ "$installed" != true ]]; then
        rm -rf "$effect_dst"
        cp -rf "$effect_src" "$effect_dst"
    fi
    echo "  ✓ Installed Geometry Change effect to $effect_dst"
fi

KWINRC="$KDE_CONFIG_DIR/kwinrc"
# Single virtual desktop for continuous horizontal carousel
set_kconfig "$KWINRC" "Desktops" "Number" "1"
set_kconfig "$KWINRC" "Desktops" "Rows" "1"

# Enable Karousel and Slide Animation plugins
set_kconfig "$KWINRC" "Plugins" "karouselEnabled" "true"
set_kconfig "$KWINRC" "Plugins" "kwin4_effect_geometry_changeEnabled" "true"
set_kconfig "$KWINRC" "Plugins" "dynamic_workspacesEnabled" "false"

# Configure Karousel: 100% full-width presets, 0 outer gaps, 0 inner gaps, centered scrolling
set_kconfig "$KWINRC" "Script-karousel" "presetWidths" "100%"
set_kconfig "$KWINRC" "Script-karousel" "gapsOuterTop" "0"
set_kconfig "$KWINRC" "Script-karousel" "gapsOuterBottom" "0"
set_kconfig "$KWINRC" "Script-karousel" "gapsOuterLeft" "0"
set_kconfig "$KWINRC" "Script-karousel" "gapsOuterRight" "0"
set_kconfig "$KWINRC" "Script-karousel" "gapsInnerHorizontal" "0"
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

# Disable conflicting KWin Quick Tile & Desktop switching shortcuts
set_kconfig "$SHORTCUTSRC" "kwin" "Window Quick Tile Left" "none,none,Quick Tile Window to the Left"
set_kconfig "$SHORTCUTSRC" "kwin" "Window Quick Tile Right" "none,none,Quick Tile Window to the Right"
set_kconfig "$SHORTCUTSRC" "kwin" "Switch to Next Desktop" "none,none,Switch to Next Desktop"
set_kconfig "$SHORTCUTSRC" "kwin" "Switch to Previous Desktop" "none,none,Switch to Previous Desktop"
set_kconfig "$SHORTCUTSRC" "kwin" "Window to Next Desktop" "none,none,Window to Next Desktop"
set_kconfig "$SHORTCUTSRC" "kwin" "Window to Previous Desktop" "none,none,Window to Previous Desktop"

for i in {1..9}; do
    set_kconfig "$SHORTCUTSRC" "kwin" "Switch to Desktop $i" "none,none,Switch to Desktop $i"
    set_kconfig "$SHORTCUTSRC" "kwin" "Window to Desktop $i" "none,none,Window to Desktop $i"
done

# Karousel Carousel Navigation & Window Movement (bound with karousel- prefix matching QML ShortcutHandler)
set_kconfig "$SHORTCUTSRC" "kwin" "karousel-focus-left" $'Meta+Left\tMeta+A,Meta+Left,Karousel: Move focus left'
set_kconfig "$SHORTCUTSRC" "kwin" "karousel-focus-right" $'Meta+Right\tMeta+D,Meta+Right,Karousel: Move focus right'
set_kconfig "$SHORTCUTSRC" "kwin" "karousel-column-move-left" "Meta+Shift+Left,Meta+Shift+Left,Karousel: Move column left"
set_kconfig "$SHORTCUTSRC" "kwin" "karousel-column-move-right" "Meta+Shift+Right,Meta+Shift+Right,Karousel: Move column right"
set_kconfig "$SHORTCUTSRC" "kwin" "karousel-window-toggle-floating" "Meta+Space,Meta+Space,Karousel: Toggle floating"
set_kconfig "$SHORTCUTSRC" "kwin" "karousel-cycle-preset-widths" "Meta+R,Meta+R,Karousel: Cycle through preset column widths"

# Legacy fallback action names without karousel- prefix
set_kconfig "$SHORTCUTSRC" "kwin" "focus-left" $'Meta+Left\tMeta+A,Meta+Left,Move focus left'
set_kconfig "$SHORTCUTSRC" "kwin" "focus-right" $'Meta+Right\tMeta+D,Meta+Right,Move focus right'
set_kconfig "$SHORTCUTSRC" "kwin" "column-move-left" "Meta+Shift+Left,Meta+Shift+Left,Move column left"
set_kconfig "$SHORTCUTSRC" "kwin" "column-move-right" "Meta+Shift+Right,Meta+Shift+Right,Move column right"
set_kconfig "$SHORTCUTSRC" "kwin" "window-toggle-floating" "Meta+Space,Meta+Space,Toggle floating"
set_kconfig "$SHORTCUTSRC" "kwin" "cycle-preset-widths" "Meta+R,Meta+R,Cycle through preset column widths"

set_kconfig "$SHORTCUTSRC" "karousel" "focus-left" $'Meta+Left\tMeta+A,Meta+Left,Move focus left'
set_kconfig "$SHORTCUTSRC" "karousel" "focus-right" $'Meta+Right\tMeta+D,Meta+Right,Move focus right'
set_kconfig "$SHORTCUTSRC" "karousel" "column-move-left" "Meta+Shift+Left,Meta+Shift+Left,Move column left"
set_kconfig "$SHORTCUTSRC" "karousel" "column-move-right" "Meta+Shift+Right,Meta+Shift+Right,Move column right"
set_kconfig "$SHORTCUTSRC" "karousel" "window-toggle-floating" "Meta+Space,Meta+Space,Toggle floating"
set_kconfig "$SHORTCUTSRC" "karousel" "cycle-preset-widths" "Meta+R,Meta+R,Cycle through preset column widths"

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

# Apply Caps Lock remap and mouse bindings if session is active
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

echo "  ✓ KDE Plasma Karousel scrolling mode, slide animations & shortcuts configured."
