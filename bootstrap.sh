#!/usr/bin/env bash
# ==============================================================================
# kdexp: Kubuntu (KDE Plasma on X11) Dotfiles Bootstrapper
# 100% Home Directory Confined — Multi-User Safe
# ==============================================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Bootstrapping kdexp dotfiles from: $DOTFILES"

# ── 1. Create User Directory Structure ────────────────────────────────────────
mkdir -p "$HOME/.config" \
         "$HOME/.local/bin" \
         "$HOME/.local/share/applications" \
         "$HOME/.local/share/wallpapers" \
         "$HOME/.config/autostart" \
         "$DOTFILES/data/browser" \
         "$DOTFILES/data/passwords"

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

# ── 6. KWin Scripts, Wallpapers & Dynamic Virtual Desktops ────────────────────
if [[ -d "$DOTFILES/config/kde/wallpapers" ]]; then
  mkdir -p "$HOME/.local/share/wallpapers"
  ln -nsf "$DOTFILES/config/kde/wallpapers" "$HOME/.local/share/wallpapers/kdexp"
  echo "  ✓ Linked Wallpapers: $HOME/.local/share/wallpapers/kdexp"
fi

if [[ -d "$DOTFILES/config/kde/kwin-scripts/dynamic_workspaces" ]]; then
  mkdir -p "$HOME/.local/share/kwin/scripts"
  ln -nsf "$DOTFILES/config/kde/kwin-scripts/dynamic_workspaces" "$HOME/.local/share/kwin/scripts/dynamic_workspaces"
  echo "  ✓ Linked KWin Script: $HOME/.local/share/kwin/scripts/dynamic_workspaces"
fi

if [[ -f "$DOTFILES/config/kde/kwinrulesrc" ]]; then
  kwinrules_target="$HOME/.config/kwinrulesrc"
  # If kwinrulesrc doesn't exist, link it; if exists, append our rule group if not present
  if [[ ! -f $kwinrules_target ]]; then
    ln -nsf "$DOTFILES/config/kde/kwinrulesrc" "$kwinrules_target"
    echo "  ✓ Linked KWin Rules: $kwinrules_target"
  elif ! grep -q "Auto Maximize Main Work Applications" "$kwinrules_target"; then
    cat "$DOTFILES/config/kde/kwinrulesrc" >> "$kwinrules_target"
    echo "  ✓ Appended auto-maximize rules to existing $kwinrules_target"
  fi
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
