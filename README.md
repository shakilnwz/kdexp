# kdexp dotfiles

Personal Linux environment & configuration for **Kubuntu (KDE Plasma 6 / 5 on Wayland & X11)** with **Bash**, **Ghostty**, and **Herdr**.

Designed specifically for shared office machines with **100% Home Directory (`$HOME`) Confinement**.

---

## 🚀 Setup & Installation

Clone this repository to `~/.kdexp`:

```bash
git clone <repo-url> ~/.kdexp
cd ~/.kdexp
./bootstrap.sh
```

### What this configures (Symlinked into place):
- **User Binaries** (`~/.local/bin/`):
  - `herdr-sessionizer`, `tmux-sessionizer`, `remap-caps`, `kdexp-browser`, `kdexp-nuke`, `cycle-display`, plus automatic `bat`/`fd` shims.
- **Shell Configuration** (`~/.bashrc` & `~/.zshrc`):
  - `stty quit undef` (resolves `Ctrl+\` SIGQUIT collision).
  - `bind -x '"\C-\\":"herdr-sessionizer"'` for interactive sessionizer in terminal.
  - Starship prompt (`~/.config/starship.toml`) with **SNXZ Palette**.
  - Aliases (`vi`, `svi`, `ta`, `hd`, `ts`, `yz`, `lg`, `ld`, `agx`).
- **KDE Plasma & KWin (X11)**:
  - **1D Dynamic Virtual Desktops (GNOME-style)**: Workspaces open dynamically as windows are created or moved to the right, and empty trailing workspaces are automatically pruned. Smooth slide transitions enabled.
  - **Auto-Maximize Rules**: Target applications (`Ghostty`, `PhpStorm`, `Zed`, `Chrome`, `Brave`, `Firefox`, `Obsidian`) open maximized.
  - **SNXZ Accent Color**: System accent set to `#7186fd` (Indigo).
  - **SNXZ Wallpapers**: Abstract wallpapers from `omarchy-snxz-theme` linked to `~/.local/share/wallpapers/kdexp`, with `1-abstract.jpg` set as default.
  - **Global Shortcuts**:
    - `Meta + Q` — Quit active application / close window.
    - `Meta + Left / Right` — Switch to previous / next virtual desktop.
    - `Meta + Shift + Left / Right` — Move active window to previous / next desktop.
    - `Meta + 1..9` — Switch to Desktop 1..9.
    - `Meta + Shift + 1..9` — Move window to Desktop 1..9.
    - `Meta + \` — Launch Herdr Sessionizer (`ghostty -e herdr-sessionizer`).
    - `Meta + Alt + \` — Launch Herdr Dual Mode (`ghostty -e herdr-sessionizer --dual`).
    - `Meta + Shift + \` — Launch Tmux Sessionizer (`ghostty -e tmux-sessionizer`).
    - `Meta + Alt + Return` — Launch Herdr Terminal (`ghostty -e herdr`).
    - `Meta + Shift + O` — Launch Obsidian.
- **Browser Cookie & Profile Isolation**:
  - `kdexp-browser` confines 100% of cookies, login tokens, extensions, and cache to `~/.kdexp/data/browser`. Default system directories (`~/.config/google-chrome`) are untouched.
- **X11 Caps Lock Remapping**:
  - `remap-caps` (`setxkbmap` + `xcape`) autostarted via `~/.config/autostart/remap-caps.desktop`.
  - Tap `Caps Lock` -> **Escape**
  - Hold `Caps Lock` -> **Control**
- **Terminal & Editor Configs (SNXZ Palette)**:
  - `~/.config/ghostty/config` (Embedded native SNXZ theme: `#00000e` background, `#c7efe3` text, `#7186fd` accent)
  - `~/.config/herdr/config.toml`
  - `~/.config/svi/` (Neovim Kickstart)

- **AI & Editor Isolation (Antigravity & Zed ACP)**:
  - **Antigravity CLI**: Confined to `~/.kdexp/data/antigravity` via `~/.gemini` symlink.
  - **Zed Assistant & ACP**: Assistant threads (`~/.local/share/zed/threads`) and state (`~/.local/state/zed`) are confined to `~/.kdexp/data/zed/` (leaving default system storage untouched).
- **Interactive Global Git Identity**:
  - Automatically prompts for `user.name` and `user.email` at the end of `bootstrap.sh` if not already set globally.
  - Headless/non-interactive environments safely bypass prompting without hanging.
- **KDE Plasma Environment Protection**:
  - `bootstrap.sh` requires KDE Plasma to be installed (`plasmashell`, `kwin_x11`, `kwriteconfig6`, etc.) and refuses to run on non-KDE environments to prevent misconfiguration.

---

## 🔒 Multi-User Safety & Total Data Wipeout (`kdexp-nuke`)

All files, symlinks, desktop entries, and scripts are strictly confined within `$HOME` (`~`).
All dynamic data (browser sessions, caches, passwords, Antigravity AI sessions, and Zed ACP conversation state) is kept inside `~/.kdexp/data/` (which is excluded from Git via `.gitignore`).

To completely wipe all session data and remove all dotfiles symlinks:
```bash
kdexp-nuke
```

---

## 📱 Password Sharing via LocalSend

1. Install **LocalSend** on your phone (Android/iOS) and office PC (`localsend`).
2. When you need your credentials, send your encrypted `.kdbx` database via LocalSend to `~/.kdexp/data/passwords/`.
3. Unlock with your master password in KeePassXC / browser extension.
4. When leaving or running `kdexp-nuke`, the entire `~/.kdexp/data/passwords/` directory is automatically wiped.

---

## 🐳 Safe Testing with Docker

### 1. Terminal / Shell Sandbox Test (CLI)
Test `./bootstrap.sh`, shell aliases, PATH, and sessionizer scripts:
```bash
./tests/run-docker-test.sh
```

### 2. Full KDE Plasma Desktop Sandbox Test (Docker Compose + noVNC Web GUI)
Start a full KDE Plasma desktop environment inside Docker and interact with it directly in your web browser:
```bash
# Using helper script
./tests/run-gui-test.sh

# Or directly via Docker Compose
docker compose up --build
```
- Open **`http://localhost:6080/vnc.html`** in your browser.
- The test environment mounts `./data/test-home` as `/home/testuser` (writable and git-ignored), allowing you to install applications, save state, and test across container restarts.
- Inside the desktop: open Konsole, run `cd ~/.kdexp && ./bootstrap.sh`, and test the desktop rules, shortcuts, and apps live.


---

## 📦 Automatic Application Installation (`apps.sh`)

To automatically install all tools, applications (Chromium, Ghostty, Obsidian, LocalSend, Zed), CLI developer utilities (Starship, Lazygit, Lazydocker), and the JetBrainsMono Nerd Font on a fresh Kubuntu system:

```bash
./apps.sh
```

Or install by category:
- `./apps.sh --cli` — Core apt packages + Starship + Lazygit + Lazydocker
- `./apps.sh --gui` — Chromium + Ghostty + Obsidian + LocalSend + Zed
- `./apps.sh --browser` — Chromium browser
- `./apps.sh --fonts` — JetBrainsMono Nerd Font

