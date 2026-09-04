#!/usr/bin/env bash
# ==============================================================================
# kdexp: Kubuntu (KDE Plasma on X11) Dotfiles Bootstrapper
# 100% Home Directory Confined — Multi-User Safe
# ==============================================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Bootstrapping kdexp dotfiles from: $DOTFILES"

# ── 0. KDE Plasma Environment Pre-check ───────────────────────────────────────
echo "==> Verifying KDE Plasma installation..."
kde_detected=false
for kde_cmd in plasmashell kwin_x11 kwin_wayland kwriteconfig6 kwriteconfig5 startplasma-x11 startplasma-wayland; do
  if command -v "$kde_cmd" >/dev/null 2>&1; then
    kde_detected=true
    echo "  ✓ Detected KDE component: $kde_cmd"
    break
  fi
done

if [[ "$kde_detected" != true ]]; then
  echo "" >&2
  echo "❌ Error: KDE Plasma does not appear to be installed on this system." >&2
  echo "   kdexp is designed exclusively for Kubuntu / KDE Plasma desktop environments." >&2
  echo "   Please install KDE Plasma (e.g. plasma-desktop, kwin-x11) before running bootstrap." >&2
  echo "" >&2
  exit 1
fi

# ── 1. Create User Directory Structure ────────────────────────────────────────
mkdir -p "$HOME/.config" \
         "$HOME/.local/bin" \
         "$HOME/.local/share/applications" \
         "$HOME/.local/share/wallpapers" \
         "$HOME/.config/autostart" \
         "$DOTFILES/data/browser" \
         "$DOTFILES/data/passwords" \
         "$DOTFILES/data/antigravity" \
         "$DOTFILES/data/zed/threads" \
         "$DOTFILES/data/zed/state"

# ── 2. Symlink User Binaries (~/.local/bin) ───────────────────────────────────
echo "==> Linking user binaries to ~/.local/bin..."
for script in "$DOTFILES/local/bin/"*; do
  [[ -f $script ]] || continue
  name="${script##*/}"
  target="$HOME/.local/bin/$name"
  chmod +x "$script"
  ln -nsf "$script" "$target"
  echo "  ✓ Linked: $target -> $script"
done

# Create user shims for Ubuntu naming differences if needed
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  ln -nsf "$(command -v batcat)" "$HOME/.local/bin/bat"
  echo "  ✓ Created shim: ~/.local/bin/bat -> batcat"
fi

if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  ln -nsf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  echo "  ✓ Created shim: ~/.local/bin/fd -> fdfind"
fi

# ── 3. Symlink Application Configurations (~/.config) ─────────────────────────
echo "==> Linking application configurations..."

# Herdr
mkdir -p "$HOME/.config/herdr"
herdr_target="$HOME/.config/herdr/config.toml"
herdr_source="$DOTFILES/config/herdr/config.toml"
if [[ -f $herdr_target && ! -L $herdr_target ]]; then
  mv "$herdr_target" "${herdr_target}.bak.$(date +%Y%m%d_%H%M%S)"
fi
ln -nsf "$herdr_source" "$herdr_target"
echo "  ✓ Linked: $herdr_target"

# Starship Prompt
starship_target="$HOME/.config/starship.toml"
starship_source="$DOTFILES/config/starship.toml"
if [[ -f $starship_target && ! -L $starship_target ]]; then
  mv "$starship_target" "${starship_target}.bak.$(date +%Y%m%d_%H%M%S)"
fi
ln -nsf "$starship_source" "$starship_target"
echo "  ✓ Linked: $starship_target"

# Ghostty Terminal
mkdir -p "$HOME/.config/ghostty"
ghostty_target="$HOME/.config/ghostty/config"
ghostty_source="$DOTFILES/config/ghostty/config"
if [[ -f $ghostty_target && ! -L $ghostty_target ]]; then
  mv "$ghostty_target" "${ghostty_target}.bak.$(date +%Y%m%d_%H%M%S)"
fi
ln -nsf "$ghostty_source" "$ghostty_target"
echo "  ✓ Linked: $ghostty_target"

# SVI (Neovim Kickstart)
if [[ -d "$DOTFILES/config/svi" ]]; then
  svi_target="$HOME/.config/svi"
  svi_source="$DOTFILES/config/svi"
  if [[ -e $svi_target && ! -L $svi_target ]]; then
    mv "$svi_target" "${svi_target}.bak.$(date +%Y%m%d_%H%M%S)"
  fi
  ln -nsf "$svi_source" "$svi_target"
  echo "  ✓ Linked: $svi_target"
fi

# Antigravity AI Data Confinement (~/.gemini -> ~/.kdexp/data/antigravity)
echo "==> Configuring Antigravity data isolation..."
mkdir -p "$DOTFILES/data/antigravity"
gemini_target="$HOME/.gemini"
if [[ -e $gemini_target && ! -L $gemini_target ]]; then
  echo "  ✓ Migrating existing ~/.gemini into ~/.kdexp/data/antigravity..."
  cp -a "$gemini_target/." "$DOTFILES/data/antigravity/" 2>/dev/null || true
  rm -rf "$gemini_target"
fi
ln -nsf "$DOTFILES/data/antigravity" "$gemini_target"
echo "  ✓ Confined Antigravity data: ~/.gemini -> ~/.kdexp/data/antigravity"

# Zed ACP & Assistant Data Confinement (~/.local/share/zed/threads & ~/.local/state/zed)
echo "==> Configuring Zed ACP & assistant data isolation..."
mkdir -p "$DOTFILES/data/zed/threads" "$DOTFILES/data/zed/state"
mkdir -p "$HOME/.local/share/zed" "$HOME/.local/state"

zed_threads_target="$HOME/.local/share/zed/threads"
if [[ -e $zed_threads_target && ! -L $zed_threads_target ]]; then
  echo "  ✓ Migrating existing ~/.local/share/zed/threads into ~/.kdexp/data/zed/threads..."
  cp -a "$zed_threads_target/." "$DOTFILES/data/zed/threads/" 2>/dev/null || true
  rm -rf "$zed_threads_target"
fi
ln -nsf "$DOTFILES/data/zed/threads" "$zed_threads_target"
echo "  ✓ Confined Zed threads: $zed_threads_target -> $DOTFILES/data/zed/threads"

zed_state_target="$HOME/.local/state/zed"
if [[ -e $zed_state_target && ! -L $zed_state_target ]]; then
  echo "  ✓ Migrating existing ~/.local/state/zed into ~/.kdexp/data/zed/state..."
  cp -a "$zed_state_target/." "$DOTFILES/data/zed/state/" 2>/dev/null || true
  rm -rf "$zed_state_target"
fi
ln -nsf "$DOTFILES/data/zed/state" "$zed_state_target"
echo "  ✓ Confined Zed state: $zed_state_target -> $DOTFILES/data/zed/state"

# ── 4. Setup Shell Configuration (~/.bashrc) ──────────────────────────────────
echo "==> Configuring Bash shell (~/.bashrc)..."
BASHRC="$HOME/.bashrc"
bash_source="$DOTFILES/rc/bashrc"
BLOCK_START='# >>> kdexp dotfiles >>>'
BLOCK_END='# <<< kdexp dotfiles <<<'

if [[ -f $BASHRC ]]; then
  tmp=$(mktemp)
  awk -v s="$BLOCK_START" -v e="$BLOCK_END" '
    index($0, s) { skip=1; next }
    index($0, e) { skip=0; next }
    !skip { print }
  ' "$BASHRC" > "$tmp"
  sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "$tmp" 2>/dev/null || true
  cat "$tmp" > "$BASHRC"
  rm -f "$tmp"
fi

if [[ -f $bash_source ]]; then
  {
    echo ""
    echo "$BLOCK_START"
    echo "export DOTFILES_DIR=\"$DOTFILES\""
    cat "$bash_source" | grep -v '# >>> kdexp dotfiles >>>' | grep -v '# <<< kdexp dotfiles <<<'
    echo "$BLOCK_END"
  } >> "$BASHRC"
  echo "  ✓ Managed shell block in $BASHRC"
fi

# ── 5. Desktop Entries & Autostart (~/.local/share/applications) ──────────────
echo "==> Linking Desktop entries & autostart..."
for app in "$DOTFILES/config/kde/applications/"*.desktop; do
  [[ -f $app ]] || continue
  name="${app##*/}"
  target="$HOME/.local/share/applications/$name"
  ln -nsf "$app" "$target"
  echo "  ✓ Linked Desktop Entry: $target"
done

for auto in "$DOTFILES/config/kde/autostart/"*.desktop; do
  [[ -f $auto ]] || continue
  name="${auto##*/}"
  target="$HOME/.config/autostart/$name"
  ln -nsf "$auto" "$target"
  echo "  ✓ Linked Autostart Entry: $target"
done

# ── 6. KWin Scripts, Effects, Wallpapers & Scrolling Window Manager ───────────
if [[ -d "$DOTFILES/config/kde/wallpapers" ]]; then
  mkdir -p "$HOME/.local/share/wallpapers"
  ln -nsf "$DOTFILES/config/kde/wallpapers" "$HOME/.local/share/wallpapers/kdexp"
  echo "  ✓ Linked Wallpapers: $HOME/.local/share/wallpapers/kdexp"
fi

# Clean up legacy dynamic_workspaces script symlink if present
rm -f "$HOME/.local/share/kwin/scripts/dynamic_workspaces"

if [[ -d "$DOTFILES/config/kde/kwin-scripts/karousel" ]]; then
  mkdir -p "$HOME/.local/share/kwin/scripts"
  ln -nsf "$DOTFILES/config/kde/kwin-scripts/karousel" "$HOME/.local/share/kwin/scripts/karousel"
  echo "  ✓ Linked KWin Script: $HOME/.local/share/kwin/scripts/karousel"
fi

if [[ -d "$DOTFILES/config/kde/kwin-effects/kwin4_effect_geometry_change" ]]; then
  mkdir -p "$HOME/.local/share/kwin/effects"
  ln -nsf "$DOTFILES/config/kde/kwin-effects/kwin4_effect_geometry_change" "$HOME/.local/share/kwin/effects/kwin4_effect_geometry_change"
  echo "  ✓ Linked KWin Effect: $HOME/.local/share/kwin/effects/kwin4_effect_geometry_change"
fi

if [[ -f "$DOTFILES/config/kde/kwinrulesrc" ]]; then
  kwinrules_target="$HOME/.config/kwinrulesrc"
  kwinrules_source="$DOTFILES/config/kde/kwinrulesrc"
  if [[ -f $kwinrules_target && ! -L $kwinrules_target ]]; then
    mv "$kwinrules_target" "${kwinrules_target}.bak.$(date +%Y%m%d_%H%M%S)"
  fi
  ln -nsf "$kwinrules_source" "$kwinrules_target"
  echo "  ✓ Linked KWin Rules: $kwinrules_target"
fi

if [[ -f "$DOTFILES/config/kde/setup-kde.sh" ]]; then
  bash "$DOTFILES/config/kde/setup-kde.sh"
fi

# ── 7. Environment & Dependency Check Summary ─────────────────────────────────
echo ""
echo "✨ kdexp bootstrap completed successfully!"
echo ""
echo "Recommended packages check:"
missing_pkgs=()
for bin in ghostty tmux fzf ripgrep starship xcape setxkbmap nvim obsidian; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    missing_pkgs+=("$bin")
  fi
done

if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
  echo "  Note: The following tools were not found in PATH:"
  echo "  ${missing_pkgs[*]}"
  echo "  Tip: You can automatically install all required applications and tools by running:"
  echo "    ./apps.sh"
else
  echo "  ✓ All core tools are installed."
fi
echo ""
echo "To apply shell changes in current terminal: source ~/.bashrc"

# ── 8. Global Git Identity Configuration ──────────────────────────────────────
if command -v git >/dev/null 2>&1; then
  current_git_name="$(git config --global user.name 2>/dev/null || true)"
  current_git_email="$(git config --global user.email 2>/dev/null || true)"

  if [[ -z "$current_git_name" || -z "$current_git_email" ]]; then
    echo ""
    echo "==> Global Git Identity Setup:"
    if [ -t 0 ]; then
      if [[ -z "$current_git_name" ]]; then
        read -rp "  Enter your Git full name (user.name): " input_name
        if [[ -n "$input_name" ]]; then
          git config --global user.name "$input_name"
          echo "  ✓ Set git user.name to: $input_name"
        else
          echo "  ⚠️ Skipped setting git user.name."
        fi
      else
        echo "  ✓ git user.name already configured: $current_git_name"
      fi

      if [[ -z "$current_git_email" ]]; then
        read -rp "  Enter your Git email (user.email): " input_email
        if [[ -n "$input_email" ]]; then
          git config --global user.email "$input_email"
          echo "  ✓ Set git user.email to: $input_email"
        else
          echo "  ⚠️ Skipped setting git user.email."
        fi
      else
        echo "  ✓ git user.email already configured: $current_git_email"
      fi
    else
      echo "  ℹ Non-interactive shell detected. Skipping interactive Git configuration."
      echo "    Tip: You can configure your Git identity manually:"
      echo "      git config --global user.name \"Your Name\""
      echo "      git config --global user.email \"you@example.com\""
    fi
  else
    echo "  ✓ Git identity already configured: $current_git_name <$current_git_email>"
  fi
fi
