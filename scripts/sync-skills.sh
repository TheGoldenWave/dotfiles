#!/usr/bin/env bash
# Sync skills from dotfiles repo to local installations
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${BLUE}[SKILLS]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Documents/dotfiles}"

# Hermes skills
HERMES_SKILLS_REPO="$DOTFILES_DIR/skills/hermes"
HERMES_SKILLS_DIR="$HOME/.hermes/skills"
if [ -d "$HERMES_SKILLS_REPO" ]; then
    info "Syncing Hermes skills..."
    mkdir -p "$HERMES_SKILLS_DIR"
    rsync -a --delete "$HERMES_SKILLS_REPO/" "$HERMES_SKILLS_DIR/"
    count=$(find "$HERMES_SKILLS_DIR" -name "SKILL.md" | wc -l | tr -d ' ')
    ok "  $count Hermes skills synced"
else
    info "No Hermes skills in dotfiles repo (add them at skills/hermes/)"
fi

# Claude Code skills
CLAUDE_SKILLS_REPO="$DOTFILES_DIR/skills/claude"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
if [ -d "$CLAUDE_SKILLS_REPO" ]; then
    info "Syncing Claude Code skills..."
    mkdir -p "$CLAUDE_SKILLS_DIR"
    rsync -a --delete "$CLAUDE_SKILLS_REPO/" "$CLAUDE_SKILLS_DIR/"
    count=$(ls -d "$CLAUDE_SKILLS_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
    ok "  $count Claude skills synced"
fi

# Codex skills
CODEX_SKILLS_REPO="$DOTFILES_DIR/skills/codex"
CODEX_SKILLS_DIR="$HOME/.codex/skills"
if [ -d "$CODEX_SKILLS_REPO" ]; then
    info "Syncing Codex skills..."
    mkdir -p "$CODEX_SKILLS_DIR"
    rsync -a --delete "$CODEX_SKILLS_REPO/" "$CODEX_SKILLS_DIR/"
    count=$(ls -d "$CODEX_SKILLS_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
    ok "  $count Codex skills synced"
fi
