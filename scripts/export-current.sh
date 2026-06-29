#!/usr/bin/env bash
# Export current environment configuration to dotfiles repo
# Run this after making changes to update the dotfiles repo
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${BLUE}[EXPORT]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Documents/dotfiles}"

if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echo -e "${RED}[ERROR]${NC} $DOTFILES_DIR is not a git repo"
    exit 1
fi

info "Exporting current configuration to $DOTFILES_DIR..."

# 1. Hermes config (sanitize secrets)
info "Exporting Hermes config..."
if [ -f "$HOME/.hermes/config.yaml" ]; then
    cat "$HOME/.hermes/config.yaml" | \
        sed -E 's/(ANTHROPIC_API_KEY: ").*?"/\1__PLAC..." | \
        sed -E 's/(BROWSERBASE_API_KEY: ").*?"/\1__PLAC..." | \
        sed -E 's/(BROWSERBASE_PROJECT_ID: ").*?"/\1__PLAC..." \
        > "$DOTFILES_DIR/dotfiles/hermes/config.yaml"
    ok "  Hermes config exported"
fi

# 2. Claude Code settings
info "Exporting Claude Code settings..."
if [ -f "$HOME/.claude/settings.json" ]; then
    cat "$HOME/.claude/settings.json" | \
        sed -E 's/("ANTHROPIC_AUTH_TOKEN": ").*?"/\1__PLAC..." \
        > "$DOTFILES_DIR/dotfiles/claude/settings.json"
    ok "  Claude settings exported"
fi

# 3. Codex config
info "Exporting Codex config..."
if [ -f "$HOME/.codex/config.toml" ]; then
    cat "$HOME/.codex/config.toml" | \
        sed -E 's/(experimental_bearer_token = ").*?"/\1__PLAC..." | \
        sed -E 's/(ANTHROPIC_AUTH_TOKEN=*** \1__PL..." \
        > "$DOTFILES_DIR/dotfiles/codex/config.toml"
    ok "  Codex config exported"
fi

# 4. Shell configs
info "Exporting shell configs..."
[ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$DOTFILES_DIR/dotfiles/zshrc"
[ -f "$HOME/.zprofile" ] && cp "$HOME/.zprofile" "$DOTFILES_DIR/dotfiles/zprofile"
[ -f "$HOME/.gitconfig" ] && cp "$HOME/.gitconfig" "$DOTFILES_DIR/dotfiles/gitconfig"
ok "  Shell configs exported"

# 5. ~/bin tools (README only, not binaries)
info "Exporting ~/bin tools list..."
mkdir -p "$DOTFILES_DIR/bin"
if [ -d "$HOME/bin" ]; then
    # Generate updated README
    cat > "$DOTFILES_DIR/bin/README.md" << 'EOF'
# ~/bin Tools

This directory contains CLI tools and scripts that should be in PATH.

## Setup

The bootstrap script automatically copies these to `~/bin/` and makes them executable.

## Tools

EOF
    for f in "$HOME/bin/"*; do
        [ -f "$f" ] || continue
        fname=$(basename "$f")
        fsize=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null || echo "unknown")
        echo "### $fname" >> "$DOTFILES_DIR/bin/README.md"
        echo "- **Size**: ${fsize}B" >> "$DOTFILES_DIR/bin/README.md"
        echo "- **Location**: ~/bin/$fname" >> "$DOTFILES_DIR/bin/README.md"
        echo "" >> "$DOTFILES_DIR/bin/README.md"
    done
    ok "  ~/bin tools list exported"
fi

# 6. Summary
info "Export summary:"
echo ""
cd "$DOTFILES_DIR"
git status --short | while read line; do
    echo "  $line"
done
echo ""

warn "Next steps:"
echo "  1. Review changes: cd $DOTFILES_DIR && git diff"
echo "  2. Stage changes: git add -A"
echo "  3. Commit: git commit -m 'update: export config from $(hostname)'"
echo "  4. Push: git push origin main"
echo ""
