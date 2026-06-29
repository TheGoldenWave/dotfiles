#!/bin/bash
# Hermes 个人资料 Git 同步脚本
# 将记忆文件同步到 profile-sync 目录并推送到 GitHub（私有仓库）

set -e

PROFILE_SYNC="$HOME/.hermes/profile-sync"
MEMORIES_SRC="$HOME/.hermes/memories"
CONFIG_SRC="$HOME/.hermes/config.yaml"

cd "$PROFILE_SYNC" || exit 1

# 1. 同步记忆文件
cp "$MEMORIES_SRC/MEMORY.md" "$PROFILE_SYNC/memories/MEMORY.md"
cp "$MEMORIES_SRC/USER.md" "$PROFILE_SYNC/memories/USER.md"

# 2. 同步配置文件
cp "$CONFIG_SRC" "$PROFILE_SYNC/config.yaml"

# 3. 检查是否有变化
git add -A
if git diff --cached --quiet; then
  exit 0
fi

# 4. 提交并推送
DATE=$(date +%Y-%m-%d_%H:%M)
CHANGED=$(git diff --cached --stat | tail -1)
git commit -m "sync: ${DATE} — ${CHANGED}"
git push origin main 2>&1

echo "✓ Profile 已同步: ${DATE}"