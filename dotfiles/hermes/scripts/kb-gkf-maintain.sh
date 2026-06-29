#!/bin/bash
# Thin Hermes cron wrapper. Real maintenance scripts live in the KB repo and sync via GitHub.
set -euo pipefail
KB_ROOT="$HOME/KnowledgeBase"
cd "$KB_ROOT"
exec bash .kb/scripts/hermes_cron_kb_maintain.sh
