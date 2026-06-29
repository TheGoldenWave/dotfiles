#!/usr/bin/env bash
set -euo pipefail

# Auto-sync Hermes memory files backed by TheGoldenWave/hermes_profile.
# Designed for Hermes cron no_agent=true:
# - no changes => empty stdout => silent
# - successful push => one concise notification
# - failures/conflicts => non-zero exit so Hermes alerts

export PATH="$HOME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

REPO="$HOME/.hermes/sync-sources/hermes_profile"
REMOTE="git@github.com:TheGoldenWave/hermes_profile.git"

if [ ! -d "$REPO/.git" ]; then
  echo "Hermes memory sync failed: repo missing at $REPO"
  exit 1
fi

cd "$REPO"
git remote set-url origin "$REMOTE"

branch="$(git rev-parse --abbrev-ref HEAD)"
if [ -z "$branch" ] || [ "$branch" = "HEAD" ]; then
  echo "Hermes memory sync failed: repo is not on a branch"
  exit 1
fi

# Commit only the memory files. Leave unrelated local changes untouched.
git add memories/MEMORY.md memories/USER.md
if ! git diff --cached --quiet -- memories/MEMORY.md memories/USER.md; then
  ts="$(date '+%Y-%m-%d_%H:%M:%S %z')"
  git commit -m "sync: ${ts} memory auto-sync" >/dev/null
fi

# Incorporate remote changes before pushing. Conflicts intentionally fail loudly.
git fetch origin >/dev/null
if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  git rebase "origin/$branch" >/dev/null
fi

# Push only when local branch is ahead.
ahead="0"
if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  ahead="$(git rev-list --count "origin/$branch..HEAD")"
else
  ahead="1"
fi

if [ "$ahead" != "0" ]; then
  git push origin "HEAD:$branch" >/dev/null
  echo "Hermes memory synced: $(git rev-parse --short HEAD)"
fi
