#!/usr/bin/env bash
# ==============================================================================
# apps.sh: Application & Development Tools Installer for Kubuntu / Ubuntu
# ==============================================================================
set -euo pipefail

log() {
    echo -e "\033[1;34m==>\033[0m \033[1m$1\033[0m"
}

success() {
    echo -e "  \033[1;32m✓\033[0m $1"
}

warn() {
    echo -e "  \033[1;33m!\033[0m $1"
}

# ── 1. Core Apt Packages ──────────────────────────────────────────────────────
install_core_apt() {
    log "Installing Core CLI & Build Tools (apt)..."
    sudo apt update
    sudo apt install -y \
        build-essential git curl wget jq unzip \
        tmux fzf bat fd-find ripgrep \
        x11-xkb-utils xcape xbindkeys neovim \
        software-properties-common ca-certificates \
        fontconfig \
        qml6-module-org-kde-notifications || sudo apt install -y qml-module-org-kde-notifications || true
    success "Core apt packages installed."
}

# ── 2. Chromium Browser ───────────────────────────────────────────────────────
install_chromium() {
    log "Installing Chromium Browser (apt)..."
    if command -v chromium >/dev/null 2>&1 || command -v chromium-browser >/dev/null 2>&1; then
        success "Chromium is already installed."
        return 0
    fi
    sudo apt install -y chromium-browser || sudo apt install -y chromium
    success "Chromium browser installed."
}

# ── 3. Ghostty Terminal ───────────────────────────────────────────────────────
install_ghostty() {
    log "Installing Ghostty Terminal..."
    if command -v ghostty >/dev/null 2>&1; then
        success "Ghostty is already installed."
        return 0
    fi

    # Try PPA first; fallback to direct .deb release
    if sudo add-apt-repository -y ppa:mkasberg/ghostty-ubuntu 2>/dev/null; then
        sudo apt update && sudo apt install -y ghostty
    else
        log "Downloading latest Ghostty .deb release..."
        tmp_deb=$(mktemp --suffix=.deb)
        if curl -fsSL "https://github.com/mkasberg/ghostty-ubuntu/releases/latest/download/ghostty_amd64.deb" -o "$tmp_deb"; then
            sudo apt install -y "$tmp_deb"
            rm -f "$tmp_deb"
        else
            warn "Could not download Ghostty .deb. You can install it manually from ghostty.org."
            rm -f "$tmp_deb"
        fi
    fi
    success "Ghostty terminal setup completed."
}

# ── 4. GUI Productivity (Obsidian, LocalSend, Zed) ────────────────────────────
install_productivity() {
    log "Installing Productivity Applications (Obsidian, LocalSend, Zed)..."

    # LocalSend
    if ! command -v localsend >/dev/null 2>&1; then
        log "Installing LocalSend..."
        tmp_deb=$(mktemp --suffix=.deb)
        localsend_url=$(curl -s https://api.github.com/repos/localsend/localsend/releases/latest | grep "browser_download_url.*linux-x86-64.deb" | cut -d '"' -f 4 | head -n 1 || true)
        if [[ -n "$localsend_url" ]]; then
            curl -fsSL "$localsend_url" -o "$tmp_deb"
            sudo apt install -y "$tmp_deb"
            rm -f "$tmp_deb"
            success "LocalSend installed."
        else
            warn "Could not fetch LocalSend download URL."
        fi
    else
        success "LocalSend is already installed."
    fi

    # Obsidian
    if ! command -v obsidian >/dev/null 2>&1; then
        log "Installing Obsidian..."
        tmp_deb=$(mktemp --suffix=.deb)
        obsidian_url=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | grep "browser_download_url.*amd64.deb" | cut -d '"' -f 4 | head -n 1 || true)
        if [[ -n "$obsidian_url" ]]; then
            curl -fsSL "$obsidian_url" -o "$tmp_deb"
            sudo apt install -y "$tmp_deb"
            rm -f "$tmp_deb"
            success "Obsidian installed."
        else
            warn "Could not fetch Obsidian download URL."
        fi
    else
        success "Obsidian is already installed."
    fi

    # Zed Editor
    if ! command -v zed >/dev/null 2>&1 && [[ ! -f "$HOME/.local/bin/zed" ]]; then
        log "Installing Zed Editor..."
        curl -f https://zed.dev/install.sh | sh || true
        success "Zed Editor installed."
    else
        success "Zed Editor is already installed."
    fi
}

# ── 5. CLI Developer Utilities (Starship, Lazygit, Lazydocker) ─────────────────
install_cli_tools() {
    log "Installing CLI Developer Tools (Starship, Lazygit, Lazydocker)..."
    mkdir -p "$HOME/.local/bin"

    # Starship
    if ! command -v starship >/dev/null 2>&1; then
        log "Installing Starship prompt..."
        curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
        success "Starship prompt installed."
    else
        success "Starship is already installed."
    fi

    # Lazygit
    if ! command -v lazygit >/dev/null 2>&1; then
        log "Installing Lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "")
        if [[ -n "$LAZYGIT_VERSION" ]]; then
            curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
            tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
            mv /tmp/lazygit "$HOME/.local/bin/lazygit"
            chmod +x "$HOME/.local/bin/lazygit"
            rm -f /tmp/lazygit.tar.gz
            success "Lazygit installed."
        fi
    else
        success "Lazygit is already installed."
    fi

    # Lazydocker
    if ! command -v lazydocker >/dev/null 2>&1; then
        log "Installing Lazydocker..."
        curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | DIR="$HOME/.local/bin" bash 2>/dev/null || true
        success "Lazydocker installed."
    else
        success "Lazydocker is already installed."
    fi
}

# ── 6. JetBrainsMono Nerd Font ────────────────────────────────────────────────
install_fonts() {
    log "Installing JetBrainsMono Nerd Font..."
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    if ! fc-list : family 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
        tmp_zip=$(mktemp --suffix=.zip)
        curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "$tmp_zip"
        mkdir -p "$FONT_DIR/JetBrainsMono"
        unzip -qo "$tmp_zip" -d "$FONT_DIR/JetBrainsMono"
        rm -f "$tmp_zip"
        fc-cache -fv "$FONT_DIR" >/dev/null 2>&1 || true
        success "Installed JetBrainsMono Nerd Font to $FONT_DIR."
    else
        success "JetBrainsMono Nerd Font is already installed."
    fi
}

# ── Entrypoint & Argument Handling ────────────────────────────────────────────
show_help() {
    echo "Usage: ./apps.sh [OPTION]"
    echo ""
    echo "Options:"
    echo "  --all        Install all tools, applications, and fonts non-interactively"
    echo "  --cli        Install core apt packages + Starship + Lazygit + Lazydocker"
    echo "  --gui        Install GUI apps (Chromium, Ghostty, Obsidian, LocalSend, Zed)"
    echo "  --browser    Install Chromium browser"
    echo "  --fonts      Install JetBrainsMono Nerd Font"
    echo "  --help       Show this help message"
    echo ""
    echo "Running without options will run the full installation."
}

MODE="${1:---all}"

case "$MODE" in
    --all)
        install_core_apt
        install_chromium
        install_ghostty
        install_productivity
        install_cli_tools
        install_fonts
        echo ""
        log "All applications and tools installed successfully!"
        log "You can now run ./bootstrap.sh to apply your configurations."
        ;;
    --cli)
        install_core_apt
        install_cli_tools
        install_fonts
        ;;
    --gui)
        install_chromium
        install_ghostty
        install_productivity
        ;;
    --browser)
        install_chromium
        ;;
    --fonts)
        install_fonts
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
    *)
        echo "Unknown option: $MODE"
        show_help
        exit 1
        ;;
esac
