#!/usr/bin/env python3
"""Git post-commit hook: auto-create/update Multica issue for tracking.

One issue per branch — consecutive commits append comments to the same issue.
main/master branches are skipped. Tracking file: .git/hooks/multica-issue-map
"""

import json, os, subprocess, sys
from pathlib import Path

# ── Config ──────────────────────────────────────────────────────────
REPO_WORKSPACE_MAP = {
    "zhiboke_claw": "直播课AI&数据",
    "goldenwave-asia": "GoldenWave",
    "personal_knowledge_base": "金波的知识库",
    "agent-config-studio": "直播课AI&数据",
}

AGENT_NAMES = {"claude", "codex", "hermes", "cursor", "copilot", "agent"}
MULTICA_BIN = os.path.expanduser("~/bin/multica")
TRACKING_FILE = ".git/hooks/multica-issue-map"

def run(cmd, timeout=10):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.stdout.strip(), r.stderr.strip(), r.returncode
    except:
        return "", str(sys.exc_info()[1]), -1

def main():
    git = ["git"]
    branch = run(git + ["branch", "--show-current"])[0]
    if not branch:
        print("[multica-hook] could not read branch", file=sys.stderr)
        return 0

    if branch in ("main", "master"):
        print(f"[multica-hook] skip {branch}", file=sys.stderr)
        return 0

    remote = run(git + ["remote", "get-url", "origin"])[0]
    workspace = None
    for k, v in REPO_WORKSPACE_MAP.items():
        if k in remote.lower():
            workspace = v
            break
    if not workspace:
        print(f"[multica-hook] no workspace for {remote}", file=sys.stderr)
        return 0

    committer = run(git + ["log", "-1", "--format=%an"])[0]
    subject = run(git + ["log", "-1", "--format=%s"])[0]
    hashref = run(git + ["log", "-1", "--format=%h"])[0]
    body = run(git + ["log", "-1", "--format=%b"])[0]

    agent_tag = " 🤖" if any(n in committer.lower() for n in AGENT_NAMES) else ""
    comment = f"{committer}{agent_tag} committed: {subject}\n`{hashref}`"
    if body:
        comment += f"\n```\n{body[:300]}\n```"

    # Load tracking
    tf = Path(TRACKING_FILE)
    tracking = {}
    if tf.exists():
        try:
            tracking = json.loads(tf.read_text())
        except:
            pass

    if branch in tracking:
        # Append comment
        issue_id = tracking[branch]
        print(f"[multica-hook] append → {issue_id}", file=sys.stderr)
        cmd = [MULTICA_BIN, "issue", "comment", "add", issue_id,
               "--body", comment, "--output", "json"]
        stdout, _, rc = run(cmd, timeout=15)
        if rc == 0:
            print(f"[multica-hook] ✓ comment added", file=sys.stderr)
        else:
            print(f"[multica-hook] ✗ {rc}", file=sys.stderr)
    else:
        # Create new issue
        print(f"[multica-hook] create → {workspace}", file=sys.stderr)
        title = subject
        cmd = [MULTICA_BIN, "issue", "create", "--title", title,
               "--workspace", workspace, "--body", comment,
               "--output", "json"]
        stdout, _, rc = run(cmd, timeout=15)
        if rc != 0:
            print(f"[multica-hook] ✗ create failed: {rc}", file=sys.stderr)
            return 1
        try:
            data = json.loads(stdout)
            issue_id = str(data.get("id") or data.get("issue_id") or data.get("number", ""))
        except:
            issue_id = stdout.strip()[:100]
        print(f"[multica-hook] ✓ {issue_id}", file=sys.stderr)
        tracking[branch] = issue_id
        tf.parent.mkdir(parents=True, exist_ok=True)
        tf.write_text(json.dumps(tracking, indent=2, ensure_ascii=False))

    return 0

if __name__ == "__main__":
    sys.exit(main())
