# snxz dotfiles

Personal Linux environment & configuration for **Omarchy Quattro (Hyprland 0.55+)**.

## 🚀 Setup & Installation

Clone this repository to `~/.dotfiles`:

```bash
git clone git@github.com:shakilnwz/dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

### What this configures (Symlinked into place):
- **Hyprland Overrides** (`~/.config/hypr/`):
  - `bindings.lua` — Application launchers (`SUPER + \` Herdr sessionizer, `SUPER + SHIFT + \` Tmux, `SUPER + SHIFT + O` Vnote, `SUPER + Q`, etc.) and mouse slide navigation.
  - `input.lua` — Repeat rate (50), delay (200), sensitivity (1), natural scrolling, 3-finger spatial slide gestures, 4-finger workspace gestures.
  - `looknfeel.lua` — Scrolling layout, 10px rounding, blur vibrancy, window rules (`KeePassXC` floating), `slide_focus` helper function.
  - `monitors.lua` — Dual-monitor configuration (`HDMI-A-2` above `eDP-1`).
- **Herdr Multiplexer** (`~/.config/herdr/config.toml`)
- **Starship Prompt** (`~/.config/starship.toml`)
- **User Binaries** (`~/.local/bin/`):
  - `cycle-display`, `herdr-sessionizer`, `tmux-sessionizer`, `vnote`
- **Quickshell Plugins** (`~/.config/omarchy/plugins/`):
  - `snxz.lock`, `snxz.menu`, `snxz.taskbar`
- **Zsh Aliases & Keybinds** (`~/.zshrc` managed from `rc/zshrc`):
  - `vi`, `svi`, `ta`, `hd`, `ts`, `yz`, `lg`, `ld`, `agx`, and `Ctrl+\` for Herdr sessionizer.

---

## 🎨 Theme Separation

Themes in Omarchy are purely visual palettes and wallpapers. You can switch between any Omarchy theme without losing your keybinds, layout, or monitor settings:

```bash
omarchy theme set tokyo-night  # Your keybindings & monitors remain 100% active
omarchy theme set snxz         # Restores SNXZ cyan/indigo visual palette
```
