# ~/bin Tools

This directory contains CLI tools and scripts that should be in PATH.

## Setup

The bootstrap script automatically copies these to `~/bin/` and makes them executable.

## Tools

### gh (GitHub CLI)
- **Size**: ~37MB
- **Source**: https://github.com/cli/cli
- **Purpose**: GitHub workflow automation
- **Auth**: `gh auth login`

### multica
- **Size**: ~13MB
- **Source**: Internal tool (作业帮)
- **Purpose**: Multi-agent orchestration
- **Config**: Requires `MULTICA_CLAUDE_PATH` and `MULTICA_CLAUDE_MODEL` env vars

### multica-post-commit.py
- **Purpose**: Git post-commit hook for multica integration
- **Usage**: Symlink to `.git/hooks/post-commit`

### opencode
- **Size**: ~0KB (wrapper script)
- **Purpose**: OpenCode CLI wrapper
- **Source**: https://github.com/nicepkg/opencode

## Adding New Tools

1. Add binary/script to this directory
2. Make executable: `chmod +x filename`
3. Commit to dotfiles repo
4. Update this README

## Windows Note

On Windows, use `.ps1` or `.bat` wrappers instead of shell scripts.
