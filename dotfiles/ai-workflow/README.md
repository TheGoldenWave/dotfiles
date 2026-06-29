# 个人 AI 工作流

> 张金波的 AI Agent Team 工作流设计与日常运维。
> 编辑 `任务要求.md` 文件即可调整 cron 行为，无需改 cron 配置。

## 核心设计文档

详细设计在知识库 wiki：

- **[AI 协同工作流优化 - 指挥官模式](https://github.com/TheGoldenWave/Personal_knowledge_base/blob/main/wiki/syntheses/AI%E5%8D%8F%E5%90%8C%E5%B7%A5%E4%BD%9C%E6%B5%81%E4%BC%98%E5%8C%96-%E6%8C%87%E6%8C%A5%E5%AE%98%E6%A8%A1%E5%BC%8F.md)**
  三层 Agent Team 架构：指挥官（Hermes）→ Squad（Multica）→ 执行 Agent（Claude Code/Codex）。
  含多设备热备、cron 日程、Squad Instructions 检查清单。

- **[个人 Agent 协作 Harness](https://github.com/TheGoldenWave/Personal_knowledge_base/blob/main/wiki/syntheses/%E4%B8%AA%E4%BA%BAAgent%E5%8D%8F%E4%BD%9CHarness.md)**
  知识库→Git→Multica 的 Agent 友好协作回路。含多设备降级策略、Git mutex cron 去重。

## Cron 任务

| 时间 | 任务 | 配置 |
|------|------|------|
| 每日 10:45 | Daily Brief（inbox + decision/pitfall） | Hermes cron `a8d3f51217eb` |
| 每日 22:00 | Knowledge Base Git auto-commit+push | Hermes cron `1ba1d89185c2` |
| 每日 22:00 | Skills 日同步（GitHub push） | Hermes cron `db29f502cac6` |
| 周五 11:00 | 数据分析 | Hermes cron `03491d1d9e7f` |
| 周五 19:05 | 周报合成 | Hermes cron `998e3c8a47a1` |

## 多设备

| 设备 | 角色 | 自动化 |
|------|------|------|
| Mac 桌面 | 主力 24/7 | Hermes cron + Multica daemon |
| MacBook | 移动办公 + 热备 | Multica daemon（cron 默认停用，需手动开启） |
| Windows PC | 消费端 | Git clone / Obsidian（建议轻编辑后 pull/push） |
| Android | 消费端 | GitHub/Obsidian Mobile 查看；重编辑回桌面处理 |

## 文件说明

- `周报合成-任务要求.md` — 周五周报的模板和规则
- `数据分析-任务要求.md` — 周五数据分析的规则
- `post-commit-multica.sh` — Git post-commit hook → Multica issue
- 其他 `.sh` — Git hooks 基础设施
