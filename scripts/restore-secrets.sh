#!/usr/bin/env bash
# Restore secrets interactively
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${BLUE}[SECRETS]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }

echo "═══════════════════════════════════════════════════"
echo "  🔐 Secret Restoration Guide"
echo "═══════════════════════════════════════════════════"
echo ""
echo "The following secrets need to be configured manually."
echo "They are NOT stored in the dotfiles repo for security."
echo ""

# ─── SSH Key ───
echo "─── 1. SSH Private Key ───"
if [ -f "$HOME/.ssh/id_ed25519" ]; then
    echo -e "${GREEN}  ✅ SSH key already exists${NC}"
else
    warn "  SSH key missing!"
    echo "  Option A: Copy from old device:"
    echo "    scp old-device:~/.ssh/id_ed25519 ~/.ssh/"
    echo "    scp old-device:~/.ssh/id_ed25519.pub ~/.ssh/"
    echo "    chmod 600 ~/.ssh/id_ed25519"
    echo ""
    echo "  Option B: Generate new key:"
    echo "    ssh-keygen -t ed25519 -C 'goldenwave0322@gmail.com'"
    echo "    Then add public key to:"
    echo "      - GitHub: https://github.com/settings/keys"
    echo "      - GitLab: https://git.zuoyebang.cc/-/profile/keys"
fi
echo ""

# ─── Hermes .env ───
echo "─── 2. Hermes .env Secrets ───"
ENV_FILE="$HOME/.hermes/.env"
if [ -f "$ENV_FILE" ]; then
    # Check if placeholders still present
    if grep -q "__PLACEHOLDER__" "$ENV_FILE"; then
        warn "  Placeholders found in $ENV_FILE"
        echo "  Edit the file and replace these values:"
        grep -n "__PLACEHOLDER__" "$ENV_FILE" | while read line; do
            echo "    $line"
        done
        echo ""
        echo "  Required secrets:"
        echo "    HERMES_CODING_PLAN_SK   — CodingPlan API key (from code.zuoyebang.cc)"
        echo "    DINGTALK_CLIENT_ID      — DingTalk app credentials"
        echo "    DINGTALK_CLIENT_SECRET  — DingTalk app credentials"
        echo "    WEIXIN_ACCOUNT_ID       — WeChat bot account"
        echo "    WEIXIN_HOME_CHANNEL     — WeChat home channel ID"
        echo "    DINGTALK_HOME_CHANNEL   — DingTalk home channel ID"
    else
        echo -e "${GREEN}  ✅ No placeholders found — secrets appear configured${NC}"
    fi
else
    warn "  $ENV_FILE not found"
    echo "  Run setup.sh first, then edit $ENV_FILE"
fi
echo ""

# ─── Claude Code ───
echo "─── 3. Claude Code Auth Token ───"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
    if grep -q "__PLACEHOLDER__" "$CLAUDE_SETTINGS"; then
        warn "  Placeholder found in $CLAUDE_SETTINGS"
        echo "  Replace ANTHROPIC_AUTH_TOKEN with your CodingPlan key"
    else
        echo -e "${GREEN}  ✅ Claude Code token appears configured${NC}"
    fi
fi
echo ""

# ─── Codex ───
echo "─── 4. Codex Auth ───"
CODEX_AUTH="$HOME/.codex/auth.json"
if [ -f "$CODEX_AUTH" ]; then
    if grep -q "__PLACEHOLDER__" "$CODEX_AUTH"; then
        warn "  Placeholder found in $CODEX_AUTH"
    else
        echo -e "${GREEN}  ✅ Codex auth appears configured${NC}"
    fi
else
    echo "  Codex auth file will be created on first 'codex' run"
fi
echo ""

# ─── GitHub CLI ───
echo "─── 5. GitHub CLI Auth ───"
if command -v gh &>/dev/null; then
    if gh auth status &>/dev/null 2>&1; then
        echo -e "${GREEN}  ✅ gh CLI authenticated${NC}"
    else
        warn "  gh CLI not authenticated"
        echo "  Run: gh auth login"
    fi
else
    warn "  gh CLI not installed"
fi
echo ""

echo "═══════════════════════════════════════════════════"
echo "After filling in secrets, run:"
echo "  source ~/.zshrc"
echo "  hermes doctor    # verify Hermes setup"
echo "═══════════════════════════════════════════════════"
