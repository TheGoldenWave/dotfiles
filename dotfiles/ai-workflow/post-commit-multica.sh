#!/bin/bash
# ============================================================================
# post-commit-multica.sh — Git post-commit hook for Multica issue auto-creation
#
# On each commit:
#   1. Maps project path → Multica workspace + project
#   2. Uses branch name as the feature/topic key
#   3. Same branch + same committer = appends to same Issue
#   4. New branch = creates new Issue
#
# IMPORTANT: Runs asynchronously (background) to never block `git commit`.
#            Multica API calls are slow (~10-30s) but the commit returns instantly.
#
# Install: symlink into .git/hooks/post-commit
# Config:  ~/Documents/AI工作流/multica-hook-config.json
# Cache:   .git/multica-hook-state  (maps branch → issue key)
# Log:     /tmp/multica-hook.log
# ============================================================================

set -euo pipefail

# ── Capture ALL git info before forking ──
PROJECT_ROOT=$(git rev-parse --show-toplevel)
COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_MSG=$(git log -1 --format='%s')
COMMIT_BODY=$(git log -1 --format='%b' | head -5)
COMMIT_AUTHOR=$(git log -1 --format='%an')
BRANCH=$(git rev-parse --abbrev-ref HEAD)
GIT_DIR=$(git rev-parse --git-dir)

# ── Fork: all Multica work happens in background ──
(
    PROJECT_ROOT="$PROJECT_ROOT"
    COMMIT_HASH="$COMMIT_HASH"
    COMMIT_MSG="$COMMIT_MSG"
    COMMIT_BODY="$COMMIT_BODY"
    COMMIT_AUTHOR="$COMMIT_AUTHOR"
    BRANCH="$BRANCH"
    GIT_DIR="$GIT_DIR"

    CONFIG_FILE="$HOME/Documents/AI工作流/multica-hook-config.json"
    MULTICA="$HOME/bin/multica"
    CACHE_FILE="$GIT_DIR/multica-hook-state"

    [ -f "$MULTICA" ] || exit 0
    [ -f "$CONFIG_FILE" ] || exit 0

    # Strip common branch prefixes to get topic
    TOPIC=$(echo "$BRANCH" | sed 's#^feature/##;s#^fix/##;s#^bugfix/##;s#^hotfix/##;s#^release/##;s#^chore/##;s#^refactor/##')

    # ── Lookup project config ──
    CONFIG=$(python3 -c "
import json, sys
root = '$PROJECT_ROOT'.rstrip('/')
with open('$CONFIG_FILE') as f:
    config = json.load(f)
for proj in config['projects']:
    if proj['path'].rstrip('/') == root:
        json.dump(proj, sys.stdout)
        sys.exit(0)
sys.exit(1)
" 2>/dev/null) || exit 0

    WORKSPACE_ID=$(echo "$CONFIG" | python3 -c "import json,sys; print(json.load(sys.stdin)['workspace_id'])")
    PROJECT_ARG=$(echo "$CONFIG" | python3 -c "
import json,sys
c = json.load(sys.stdin)
pid = c.get('project_id', '')
print(pid if pid else c.get('project_name', ''))
")
    WS_NAME=$(echo "$CONFIG" | python3 -c "import json,sys; print(json.load(sys.stdin).get('workspace_name','?'))")

    [ -n "$PROJECT_ARG" ] || exit 0

    # ── Resolve project_id if only name was given ──
    if ! echo "$PROJECT_ARG" | grep -qE '^[0-9a-f]{6,}$'; then
        PID_CACHE="$HOME/.hermes/multica-project-id-cache.json"
        touch "$PID_CACHE" 2>/dev/null
        CACHED_ID=$(python3 -c "
import json, sys
try:
    with open('$PID_CACHE') as f:
        cache = json.load(f)
    print(cache.get('${WORKSPACE_ID}:${PROJECT_ARG}', ''))
except: pass
" 2>/dev/null)

        if [ -n "$CACHED_ID" ]; then
            PROJECT_ARG="$CACHED_ID"
        else
            "$MULTICA" config set workspace_id "$WORKSPACE_ID" >/dev/null 2>&1
            RESOLVED=$(python3 -c "
import subprocess
try:
    result = subprocess.run(['$MULTICA', 'project', 'list'],
        capture_output=True, text=True, timeout=20)
    for line in result.stdout.split('\n'):
        parts = line.split()
        if len(parts) >= 2 and '$PROJECT_ARG'.lower() in line.lower():
            pid = parts[0]
            cache = {}
            try:
                with open('$PID_CACHE') as f:
                    cache = json.load(f)
            except: pass
            cache['${WORKSPACE_ID}:${PROJECT_ARG}'] = pid
            with open('$PID_CACHE', 'w') as f:
                json.dump(cache, f)
            print(pid)
            sys.exit(0)
except Exception:
    pass
" 2>/dev/null)
            [ -n "$RESOLVED" ] && PROJECT_ARG="$RESOLVED"
        fi
    fi

    # ── Switch workspace ──
    "$MULTICA" config set workspace_id "$WORKSPACE_ID" >/dev/null 2>&1

    # ── Dedup: check cache for existing issue ──
    DEDUP_KEY="${TOPIC}:${COMMIT_AUTHOR}"
    touch "$CACHE_FILE" 2>/dev/null
    CACHED_ISSUE=$(grep "^${DEDUP_KEY}=" "$CACHE_FILE" 2>/dev/null | tail -1 | cut -d= -f2 || true)

    DESC_FILE=$(mktemp /tmp/multica-hook-desc.XXXXXX)

    if [ -n "$CACHED_ISSUE" ]; then
        # ── Append comment ──
        cat > "$DESC_FILE" << COMMENT_EOF
### 💻 Commit ${COMMIT_HASH:0:7}

**${COMMIT_MSG}**

\`\`\`
${COMMIT_BODY}
\`\`\`
COMMENT_EOF

        if "$MULTICA" issue comment add "$CACHED_ISSUE" --content-file "$DESC_FILE" >/dev/null 2>&1; then
            echo "[multica-hook] 📎 ${CACHED_ISSUE} ← ${COMMIT_HASH:0:7} (${TOPIC})"
        else
            echo "[multica-hook] ⚠️ Failed to comment on ${CACHED_ISSUE}"
        fi
    else
        # ── Create new issue ──
        ISSUE_TITLE="[${TOPIC}] ${COMMIT_MSG}"

        cat > "$DESC_FILE" << ISSUE_EOF
### 🚀 初始 Commit: ${COMMIT_HASH:0:7}

**作者:** ${COMMIT_AUTHOR}
**分支:** ${BRANCH}

${COMMIT_MSG}

\`\`\`
${COMMIT_BODY}
\`\`\`

---
📌 此 Issue 由 git post-commit hook 自动创建（${WS_NAME}）
🔗 同一分支的后续提交将追加评论到此 Issue
ISSUE_EOF

        RESULT=$("$MULTICA" issue create \
            --title "$ISSUE_TITLE" \
            --project "$PROJECT_ARG" \
            --priority medium \
            --description-file "$DESC_FILE" \
            --output json 2>&1)

        ISSUE_KEY=$(echo "$RESULT" | python3 -c "
import json,sys
try:
    data = json.load(sys.stdin)
    # identifier is the human-readable key like 'AI-42'
    print(data.get('identifier', ''))
except:
    pass
" 2>/dev/null || echo "")

        if [ -n "$ISSUE_KEY" ]; then
            echo "${DEDUP_KEY}=${ISSUE_KEY}" >> "$CACHE_FILE"
            echo "[multica-hook] ✅ ${ISSUE_KEY} ← ${COMMIT_HASH:0:7} (${TOPIC})"
        else
            echo "[multica-hook] ⚠️ Created but could not parse key"
        fi
    fi

    rm -f "$DESC_FILE"

) >> /tmp/multica-hook.log 2>&1 &

exit 0