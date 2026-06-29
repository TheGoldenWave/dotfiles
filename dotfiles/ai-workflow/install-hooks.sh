#!/bin/bash
# ============================================================================
# install-hooks.sh — 为指定项目安装 Multica post-commit hook
#
# Usage:
#   bash ~/Documents/AI工作流/install-hooks.sh /path/to/project
#
# 做了什么：
#   1. 检查项目是否有 .git
#   2. 如果已有 hook，创建 wrapper 链式调用
#   3. 如果无 hook，symlink 到统一脚本
#   4. 添加 multica-hook-state 到 .gitignore
#   5. 如果需要，更新 multica-hook-config.json
# ============================================================================

set -euo pipefail

PROJECT_PATH="$1"
HOOK_DIR="$HOME/Documents/AI工作流"
HOOK_SCRIPT="$HOOK_DIR/post-commit-multica.sh"
CONFIG_FILE="$HOOK_DIR/multica-hook-config.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [ -z "$PROJECT_PATH" ]; then
    echo -e "${RED}用法: $0 /path/to/project${NC}"
    exit 1
fi

PROJECT_PATH=$(cd "$PROJECT_PATH" && pwd)

# 1. Check .git
if [ ! -d "$PROJECT_PATH/.git" ]; then
    echo -e "${RED}❌ $PROJECT_PATH 不是 Git 仓库${NC}"
    exit 1
fi

GIT_HOOK="$PROJECT_PATH/.git/hooks/post-commit"

echo "📦 项目: $PROJECT_PATH"

# 2. Install hook
if [ -f "$GIT_HOOK" ]; then
    # Check if it's already our script (symlink)
    if [ -L "$GIT_HOOK" ] && [ "$(readlink "$GIT_HOOK")" = "$HOOK_SCRIPT" ]; then
        echo -e "${GREEN}  ✅ hook 已安装（symlink）${NC}"
    else
        # Check if already contains our call
        if grep -q "post-commit-multica.sh" "$GIT_HOOK" 2>/dev/null; then
            echo -e "${GREEN}  ✅ hook 已链式集成${NC}"
        else
            # Create wrapper
            WRAPPER="$PROJECT_PATH/.git/hooks/post-commit"
            mv "$WRAPPER" "$WRAPPER.bak"
            cat > "$WRAPPER" << WRAPPER_EOF
#!/usr/bin/env bash
# Chained post-commit wrapper — preserves existing hook
REPO_ROOT=\$(git rev-parse --show-toplevel)

# 1. Existing hook (backed up)
if [ -f "$WRAPPER.bak" ]; then
    bash "$WRAPPER.bak"
fi

# 2. Multica issue auto-tracking
bash "$HOOK_SCRIPT"
WRAPPER_EOF
            chmod +x "$WRAPPER"
            echo -e "${GREEN}  ✅ 创建 wrapper（原 hook → .bak）${NC}"
        fi
    fi
else
    ln -sf "$HOOK_SCRIPT" "$GIT_HOOK"
    echo -e "${GREEN}  ✅ symlink → $HOOK_SCRIPT${NC}"
fi

# 3. Add to .gitignore
GITIGNORE="$PROJECT_PATH/.gitignore"
touch "$GITIGNORE"
if ! grep -q "^multica-hook-state\$" "$GITIGNORE" 2>/dev/null; then
    echo "multica-hook-state" >> "$GITIGNORE"
    echo -e "${GREEN}  ✅ .gitignore 已添加${NC}"
else
    echo "  ⏭  .gitignore 已有"
fi

echo ""
echo -e "${GREEN}🎉 安装完成！${NC}"
echo "  下次 git commit 时自动在 Multica 创建/更新 Issue"
echo "  日志: /tmp/multica-hook.log"
echo "  如需添加项目到配置: 编辑 $CONFIG_FILE"