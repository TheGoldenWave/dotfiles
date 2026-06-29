#!/usr/bin/env bash
# ═══════════════════════════════════════════════════
# GoldenWave Dev Environment Bootstrap (macOS/Linux)
# ═══════════════════════════════════════════════════
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Documents/dotfiles}"
REPO_URL="git@github.com:TheGoldenWave/dotfiles.git"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        arm64|aarch64) echo "arm64" ;;
        x86_64)        echo "x64" ;;
        *)             echo "unknown" ;;
    esac
}

OS=$(detect_os)
ARCH=$(detect_arch)
info "Detected: $OS / $ARCH"

# ─── Phase 0: Clone repo if needed ───
if [ ! -d "$DOTFILES_DIR/.git" ]; then
    info "Cloning dotfiles repository..."
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    if command -v git &>/dev/null && ssh -T git@github.com 2>&1 | grep -q "success\|Hi "; then
        git clone "$REPO_URL" "$DOTFILES_DIR" 2>/dev/null || {
            warn "SSH clone failed, trying HTTPS..."
            git clone "https://github.com/TheGoldenWave/dotfiles.git" "$DOTFILES_DIR"
        }
        ok "Repository cloned"
    else
        warn "No git or SSH key yet — create dotfiles dir for manual setup"
        mkdir -p "$DOTFILES_DIR"
    fi
fi

# ─── Phase 1: Homebrew (macOS) ───
if [ "$OS" = "macos" ]; then
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Apple Silicon path
        if [ "$ARCH" = "arm64" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        ok "Homebrew installed"
    fi
fi

# ─── Phase 2: Core CLI tools ───
info "Installing core tools..."
if [ "$OS" = "macos" ]; then
    bash "$DOTFILES_DIR/scripts/install-tools-mac.sh"
fi

# ─── Phase 3: Node.js ───
if ! command -v node &>/dev/null; then
    info "Installing Node.js..."
    if [ "$OS" = "macos" ]; then
        brew install node
    else
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
        sudo apt-get install -y nodejs
    fi
    ok "Node.js $(node --version) installed"
fi

# ─── Phase 4: Python ───
if ! command -v python3 &>/dev/null; then
    if [ "$OS" = "macos" ]; then
        brew install python@3.13
    else
        sudo apt-get install -y python3 python3-pip python3-venv
    fi
    ok "Python installed"
fi

# ─── Phase 5: Shell config ───
info "Setting up shell configuration..."
for f in zshrc zprofile; do
    target="$HOME/.$f"
    if [ -f "$DOTFILES_DIR/dotfiles/$f" ]; then
        if [ -f "$target" ]; then
            cp "$target" "${target}.bak.$(date +%Y%m%d)"
            info "  Backed up existing $target"
        fi
        cp "$DOTFILES_DIR/dotfiles/$f" "$target"
        ok "  $target installed"
    fi
done

# Git config
if [ -f "$DOTFILES_DIR/dotfiles/gitconfig" ]; then
    cp "$DOTFILES_DIR/dotfiles/gitconfig" "$HOME/.gitconfig"
    ok "Git config installed"
fi

# ─── Phase 6: Hermes Agent ───
info "Setting up Hermes Agent..."
if ! command -v hermes &>/dev/null; then
    info "  Installing Hermes..."
    if [ -f "$DOTFILES_DIR/hermes-setup" ]; then
        chmod +x "$DOTFILES_DIR/hermes-setup"
        "$DOTFILES_DIR/hermes-setup"
    else
        curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    fi
fi

# Hermes config
HERMES_DIR="$HOME/.hermes"
mkdir -p "$HERMES_DIR"

if [ -f "$DOTFILES_DIR/dotfiles/hermes/config.yaml" ]; then
    if [ -f "$HERMES_DIR/config.yaml" ]; then
        cp "$HERMES_DIR/config.yaml" "$HERMES_DIR/config.yaml.bak.$(date +%Y%m%d)"
    fi
    cp "$DOTFILES_DIR/dotfiles/hermes/config.yaml" "$HERMES_DIR/config.yaml"
    ok "  Hermes config installed"
fi

# Hermes .env template
if [ -f "$DOTFILES_DIR/dotfiles/hermes/env.template" ]; then
    if [ ! -f "$HERMES_DIR/.env" ]; then
        cp "$DOTFILES_DIR/dotfiles/hermes/env.template" "$HERMES_DIR/.env"
        warn "  Hermes .env created — EDIT SECRETS BEFORE USE"
    else
        info "  Hermes .env already exists, skipping"
    fi
fi

# ─── Phase 7: Claude Code ───
info "Setting up Claude Code..."
if ! command -v claude &>/dev/null; then
    npm install -g @anthropic-ai/claude-code 2>/dev/null || warn "Claude Code install failed"
fi

CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"
if [ -f "$DOTFILES_DIR/dotfiles/claude/settings.json" ]; then
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
        cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak.$(date +%Y%m%d)"
    fi
    cp "$DOTFILES_DIR/dotfiles/claude/settings.json" "$CLAUDE_DIR/settings.json"
    ok "  Claude Code settings installed"
fi

# ─── Phase 8: Codex ───
info "Setting up Codex..."
if ! command -v codex &>/dev/null; then
    npm install -g @openai/codex 2>/dev/null || warn "Codex install failed"
fi

CODEX_DIR="$HOME/.codex"
mkdir -p "$CODEX_DIR"
if [ -f "$DOTFILES_DIR/dotfiles/codex/config.toml" ]; then
    if [ -f "$CODEX_DIR/config.toml" ]; then
        cp "$CODEX_DIR/config.toml" "$CODEX_DIR/config.toml.bak.$(date +%Y%m%d)"
    fi
    cp "$DOTFILES_DIR/dotfiles/codex/config.toml" "$CODEX_DIR/config.toml"
    ok "  Codex config installed"
fi

# ─── Phase 9: ~/bin tools ───
info "Setting up ~/bin tools..."
mkdir -p "$HOME/bin"
if [ -d "$DOTFILES_DIR/bin" ]; then
    for f in "$DOTFILES_DIR/bin/"*; do
        [ -f "$f" ] || continue
        fname=$(basename "$f")
        [ "$fname" = "README.md" ] && continue
        cp "$f" "$HOME/bin/$fname"
        chmod +x "$HOME/bin/$fname"
        ok "  ~/bin/$fname installed"
    done
fi

# ─── Phase 10: NPM global packages ───
info "Installing npm global packages..."
NPM_GLOBALS=(bun @anthropic-ai/claude-code @openai/codex @tarojs/cli)
for pkg in "${NPM_GLOBALS[@]}"; do
    if ! npm list -g "$pkg" &>/dev/null 2>&1; then
        npm install -g "$pkg" 2>/dev/null && ok "  $pkg installed" || warn "  $pkg install failed"
    fi
done

# ─── Phase 11: Clone repos ───
info "Cloning project repositories..."
bash "$DOTFILES_DIR/scripts/clone-repos.sh" 2>/dev/null || warn "Some repos failed to clone"

# ─── Phase 12: Skills sync ───
info "Syncing skills..."
bash "$DOTFILES_DIR/scripts/sync-skills.sh" 2>/dev/null || warn "Skills sync had issues"

# ─── Phase 13: SSH key ───
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    warn "No SSH key found!"
    warn "Options:"
    warn "  1. Copy from old device: scp old-device:~/.ssh/id_ed25519 ~/.ssh/"
    warn "  2. Generate new: ssh-keygen -t ed25519 -C 'goldenwave0322@gmail.com'"
    warn "     Then add to GitHub: https://github.com/settings/keys"
fi

# ─── Phase 14: SeaDrive / Knowledge Base ───
info "Checking SeaDrive..."
if [ ! -d "$HOME/Library/CloudStorage/SeaDrive" ] && [ ! -d "$HOME/SeaDrive" ]; then
    warn "SeaDrive not found. Install from: https://www.seafile.com/en/download/"
    warn "After install, sign in and wait for sync."
fi

# ─── Done ───
echo ""
echo "═══════════════════════════════════════════════════"
echo -e "${GREEN}✅ Bootstrap complete!${NC}"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Edit secrets:  bash ~/Documents/dotfiles/scripts/restore-secrets.sh"
echo "  2. Reload shell:  source ~/.zshrc"
echo "  3. Test Hermes:   hermes"
echo "  4. Test Claude:   claude"
echo "  5. Test Codex:    codex"
echo ""
