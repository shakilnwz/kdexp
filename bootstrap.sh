#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Bootstrapping dotfiles from: $DOTFILES"

# ── 1. Symlink Hyprland user override files ───────────────────────────────────
mkdir -p "$HOME/.config/hypr"
for f in bindings.lua input.lua looknfeel.lua monitors.lua; do
  target="$HOME/.config/hypr/$f"
  source="$DOTFILES/config/hypr/$f"
  if [[ -f $target && ! -L $target ]]; then
    backup="${target}.bak.$(date +%Y%m%d_%H%M%S)"
    echo "  Backing up existing $target -> $backup"
    mv "$target" "$backup"
  fi
  ln -nsf "$source" "$target"
  echo "  ✓ Linked: $target -> $source"
done

# ── 2. Symlink Herdr config ───────────────────────────────────────────────────
mkdir -p "$HOME/.config/herdr"
herdr_target="$HOME/.config/herdr/config.toml"
herdr_source="$DOTFILES/config/herdr/config.toml"
if [[ -f $herdr_target && ! -L $herdr_target ]]; then
  backup="${herdr_target}.bak.$(date +%Y%m%d_%H%M%S)"
  echo "  Backing up existing $herdr_target -> $backup"
  mv "$herdr_target" "$backup"
fi
ln -nsf "$herdr_source" "$herdr_target"
echo "  ✓ Linked: $herdr_target -> $herdr_source"

# ── 3. Symlink Starship config ────────────────────────────────────────────────
mkdir -p "$HOME/.config"
starship_target="$HOME/.config/starship.toml"
starship_source="$DOTFILES/config/starship.toml"
if [[ -f $starship_target && ! -L $starship_target ]]; then
  backup="${starship_target}.bak.$(date +%Y%m%d_%H%M%S)"
  echo "  Backing up existing $starship_target -> $backup"
  mv "$starship_target" "$backup"
fi
ln -nsf "$starship_source" "$starship_target"
echo "  ✓ Linked: $starship_target -> $starship_source"

# ── 4. Symlink Terminal Configs (Foot & Ghostty) ──────────────────────────────
mkdir -p "$HOME/.config/foot" "$HOME/.config/ghostty"

foot_target="$HOME/.config/foot/foot.ini"
foot_source="$DOTFILES/config/foot/foot.ini"
if [[ -f $foot_target && ! -L $foot_target ]]; then
  backup="${foot_target}.bak.$(date +%Y%m%d_%H%M%S)"
  echo "  Backing up existing $foot_target -> $backup"
  mv "$foot_target" "$backup"
fi
ln -nsf "$foot_source" "$foot_target"
echo "  ✓ Linked: $foot_target -> $foot_source"

ghostty_target="$HOME/.config/ghostty/config"
ghostty_source="$DOTFILES/config/ghostty/config"
if [[ -f $ghostty_target && ! -L $ghostty_target ]]; then
  backup="${ghostty_target}.bak.$(date +%Y%m%d_%H%M%S)"
  echo "  Backing up existing $ghostty_target -> $backup"
  mv "$ghostty_target" "$backup"
fi
ln -nsf "$ghostty_source" "$ghostty_target"
echo "  ✓ Linked: $ghostty_target -> $ghostty_source"

# ── 4.5. Symlink SVI (Neovim) Config ──────────────────────────────────────────
svi_target="$HOME/.config/svi"
svi_source="$DOTFILES/config/svi"
if [[ -e $svi_target && ! -L $svi_target ]]; then
  backup="${svi_target}.bak.$(date +%Y%m%d_%H%M%S)"
  echo "  Backing up existing $svi_target -> $backup"
  mv "$svi_target" "$backup"
fi
ln -nsf "$svi_source" "$svi_target"
echo "  ✓ Linked: $svi_target -> $svi_source"

# ── 5. Symlink Personal Binaries ──────────────────────────────────────────────
mkdir -p "$HOME/.local/bin"
for script in "$DOTFILES/local/bin/"*; do
  [[ -f $script ]] || continue
  name="${script##*/}"
  target="$HOME/.local/bin/$name"
  ln -nsf "$script" "$target"
  chmod +x "$script"
  echo "  ✓ Linked: $target -> $script"
done

# Clean up old ~/.local/bin/snxz if present
if [[ -d "$HOME/.local/bin/snxz" ]]; then
  rm -rf "$HOME/.local/bin/snxz"
  echo "  ✓ Removed legacy ~/.local/bin/snxz directory"
fi

# ── 6. Symlink Quickshell Plugins ─────────────────────────────────────────────
mkdir -p "$HOME/.config/omarchy/plugins"
for plugin_dir in "$DOTFILES/config/omarchy/plugins/"*; do
  [[ -d $plugin_dir ]] || continue
  pname="${plugin_dir##*/}"
  ptarget="$HOME/.config/omarchy/plugins/$pname"
  if [[ -d $ptarget && ! -L $ptarget ]]; then
    rm -rf "$ptarget"
  fi
  ln -nsf "$plugin_dir" "$ptarget"
  echo "  ✓ Linked Plugin: $ptarget -> $plugin_dir"
done

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin enable snxz.lock >/dev/null 2>&1 || true
  omarchy plugin enable snxz.menu >/dev/null 2>&1 || true
  omarchy plugin enable snxz.taskbar >/dev/null 2>&1 || true
fi

# ── 7. Inject / Update .zshrc Block ───────────────────────────────────────────
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
zsh_source="$DOTFILES/rc/zshrc"
BLOCK_START='# >>> snxz dotfiles >>>'
BLOCK_END='# <<< snxz dotfiles <<<'
OLD_START='# >>> snxz theme >>>'
OLD_END='# <<< snxz theme <<<'

if [[ -f $ZSHRC ]]; then
  tmp=$(mktemp)
  awk -v s1="$OLD_START" -v e1="$OLD_END" -v s2="$BLOCK_START" -v e2="$BLOCK_END" '
    index($0, s1) || index($0, s2) { skip=1; next }
    index($0, e1) || index($0, e2) { skip=0; next }
    !skip { print }
  ' "$ZSHRC" > "$tmp"
  sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "$tmp" 2>/dev/null || true
  cat "$tmp" > "$ZSHRC"
  rm -f "$tmp"
fi

if [[ -f $zsh_source ]]; then
  {
    echo ""
    echo "$BLOCK_START"
    cat "$zsh_source"
    echo "$BLOCK_END"
  } >> "$ZSHRC"
  echo "  ✓ Managed shell configuration in $ZSHRC (from $zsh_source)"
fi

# ── 8. Install / Update and Apply SNXZ Theme from Git (HTTPS) ─────────────────
THEME_NAME="snxz"
THEME_DIR="$HOME/.config/omarchy/themes/$THEME_NAME"
THEME_GIT_HTTPS="https://github.com/shakilnwz/omarchy-snxz-theme.git"

if command -v omarchy >/dev/null 2>&1; then
  if [[ -d "$THEME_DIR/.git" ]]; then
    echo "  Updating installed theme $THEME_NAME via git pull..."
    git -C "$THEME_DIR" pull --ff-only 2>/dev/null || true
  elif [[ ! -e "$THEME_DIR" ]]; then
    echo "  Installing theme $THEME_NAME via Omarchy (HTTPS)..."
    omarchy theme install "$THEME_GIT_HTTPS" 2>/dev/null || echo "  Theme install skipped (push to GitHub first, then run 'omarchy theme install $THEME_GIT_HTTPS')"
  fi

  if [[ -d "$THEME_DIR" ]]; then
    omarchy theme set "$THEME_NAME" >/dev/null 2>&1 || true
    echo "  ✓ Applied theme: $THEME_NAME"
  fi
fi

echo ""
echo "✨ Dotfiles bootstrap complete!"
echo "Run 'hyprctl reload' to apply Hyprland changes."
