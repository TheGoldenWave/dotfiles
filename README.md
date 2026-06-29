# 🌊 GoldenWave Dotfiles & Dev Environment Bootstrap

张金波 (Jason Zhang) 的个人工作环境一键部署方案。
支持 macOS (Apple Silicon / Intel) 和 Windows。

## 🚀 Quick Start

### macOS
```bash
# 一行搞定
bash <(curl -fsSL https://raw.githubusercontent.com/TheGoldenWave/dotfiles/main/setup.sh)

# 或 clone 后本地运行
git clone git@github.com:TheGoldenWave/dotfiles.git ~/Documents/dotfiles
bash ~/Documents/dotfiles/setup.sh
```

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/TheGoldenWave/dotfiles/main/setup.ps1 | iex
```

## 📦 包含内容

| 组件 | 说明 |
|------|------|
| **Hermes Agent** | AI Agent 运行时 + 配置 + 101 个 skills |
| **Claude Code** | Anthropic 编码助手 + 模型路由配置 |
| **Codex** | OpenAI 编码助手 + 模型路由配置 |
| **Shell** | zsh 配置 (PATH / alias / 模型切换) |
| **SSH** | ed25519 密钥 (需手动恢复) |
| **Git** | 全局 safe.directory 配置 |
| **CLI 工具** | gh, multica, opencode 等 ~/bin 工具 |
| **Node 全局包** | claude-code, codex, bun, tarojs 等 |
| **Homebrew** | ripgrep, ffmpeg, tmux 等 |
| **项目仓库** | goldenwave-asia, Zhiboke_Claw 等 |
| **知识库** | SeaDrive / Personal_knowledge_base |

## 🔐 安全说明

- 所有配置文件中的 **API Key / Token / Secret** 已替换为占位符 `__PLACEHOLDER__`
- 首次部署后需要手动填入密钥（见 `scripts/restore-secrets.sh`）
- SSH 私钥不在此仓库中，需要从旧设备手动拷贝或重新生成

## 📁 目录结构

```
dotfiles/
├── README.md              # 本文件
├── setup.sh               # macOS/Linux 一键部署
├── setup.ps1              # Windows 一键部署
├── dotfiles/
│   ├── hermes/
│   │   ├── config.yaml    # Hermes 主配置
│   │   └── env.template   # 环境变量模板
│   ├── claude/
│   │   └── settings.json  # Claude Code 配置
│   ├── codex/
│   │   └── config.toml    # Codex 配置
│   ├── zshrc              # Shell 配置
│   ├── zprofile           # Shell Profile
│   └── gitconfig          # Git 全局配置
├── bin/
│   └── README.md          # ~/bin 工具说明
└── scripts/
    ├── install-tools-mac.sh    # macOS 工具安装
    ├── install-tools-win.ps1   # Windows 工具安装
    ├── clone-repos.sh          # 项目仓库 clone
    ├── restore-secrets.sh      # 密钥恢复引导
    └── sync-skills.sh          # Skills 同步
```

## 🔄 维护

```bash
# 更新 dotfiles 仓库
cd ~/Documents/dotfiles && git pull

# 从当前设备导出最新配置到 dotfiles
bash scripts/export-current.sh

# 提交变更
git add -A && git commit -m "update: $(date +%Y%m%d)" && git push
```
