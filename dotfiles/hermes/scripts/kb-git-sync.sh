#!/bin/bash
# 知识库每日 Git 同步脚本
# 【新架构 2026-06-26】权威仓库已迁到本地 SSD ~/KnowledgeBase
# 不再在 SeaDrive 路径做 git (mmap failed 卡死)。直接调用本地仓库的 sync.sh。
set -euo pipefail

KB_PATH="$HOME/KnowledgeBase"

if [ ! -d "$KB_PATH/.git" ]; then
  echo "✗ 本地权威仓库不存在: $KB_PATH"
  exit 1
fi

cd "$KB_PATH"

# 无变更则静默退出 (watchdog 模式)
if [ -z "$(git status --porcelain)" ]; then
  exit 0
fi

DATE=$(date +%Y-%m-%d)
CHANGED=$(git status --porcelain | wc -l | tr -d ' ')

# 复用 sync.sh: commit + push GitHub
bash "$KB_PATH/sync.sh" "sync: ${DATE} 知识库变更 (${CHANGED} 个文件)" 2>&1

echo "✓ 知识库已同步: ${DATE} — ${CHANGED} 个文件变更"
