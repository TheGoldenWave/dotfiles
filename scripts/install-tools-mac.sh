#!/usr/bin/env bash
# macOS tool installation
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${BLUE}[TOOLS]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }

# Homebrew packages
BREW_PACKAGES=(ripgrep ffmpeg tmux coreutils tree jq)
for pkg in "${BREW_PACKAGES[@]}"; do
    if brew list "$pkg" &>/dev/null 2>&1; then
        ok "  $pkg already installed"
    else
        info "  Installing $pkg..."
        brew install "$pkg" && ok "  $pkg installed" || warn "  $pkg failed"
    fi
done

# GitHub CLI
if ! command -v gh &>/dev/null; then
    info "  Installing GitHub CLI..."
    brew install gh
    ok "  gh installed — run 'gh auth login' to authenticate"
fi

# zcode (ZCode / Claude Code wrapper)
if ! command -v zcode &>/dev/null; then
    info "  Installing zcode..."
    curl -fsSL https://code.yukework.com/install.sh | bash && ok "  zcode installed" || warn "  zcode failed"
fi
