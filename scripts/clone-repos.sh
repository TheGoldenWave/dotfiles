#!/usr/bin/env bash
# Clone project repositories
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${BLUE}[REPOS]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }

clone_repo() {
    local url="$1" target="$2"
    if [ -d "$target/.git" ]; then
        ok "  $(basename "$target") already cloned"
    else
        info "  Cloning $(basename "$target")..."
        mkdir -p "$(dirname "$target")"
        if git clone "$url" "$target" 2>/dev/null; then
            ok "  $(basename "$target") cloned"
        else
            # Try HTTPS via ghfast.top proxy
            local https_url="https://ghfast.top/$url"
            if git clone "$https_url" "$target" 2>/dev/null; then
                ok "  $(basename "$target") cloned (via proxy)"
            else
                echo -e "${YELLOW}[WARN]${NC}  $(basename "$target") failed"
            fi
        fi
    fi
}

# Personal repos (GitHub)
clone_repo "git@github.com:TheGoldenWave/goldenwave-asia.git" \
    "$HOME/Documents/MyProject/goldenwave-asia"

clone_repo "git@github.com:TheGoldenWave/Personal_knowledge_base.git" \
    "$HOME/Library/CloudStorage/SeaDrive-张金波(10.250.8.32)/我的资料库/Knowledge"

# Work repos (internal GitLab) — only if SSH key has access
clone_repo "git@git.zuoyebang.cc:pkg/zcode-marketplace.git" \
    "$HOME/Documents/MyProject/zcode-marketplace" 2>/dev/null || true
