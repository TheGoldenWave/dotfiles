#!/bin/bash
# Hermes Skills 每周 Git 同步脚本
SKILLS_PATH="$HOME/.hermes/skills/domain"

cd "$SKILLS_PATH" || exit 1

# Check if there are changes
git add -A
if git diff --cached --quiet; then
  # No changes, stay silent
  exit 0
fi

# Commit and push
DATE=$(date +%Y-%m-%d)
CHANGED=$(git diff --cached --stat | tail -1)
git commit -m "sync: ${DATE} skills update (${CHANGED})"
git push origin main 2>&1

echo "✓ Skills 已同步: ${DATE} — ${CHANGED}"
