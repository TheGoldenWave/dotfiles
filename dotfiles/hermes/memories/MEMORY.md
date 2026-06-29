macOS environment: `timeout` not available (use gtimeout or Python timeouts). Python is `python3`. No `go` installed.
§
个人知识库【纯git架构 2026-06-27】: 权威仓库+Obsidian vault均为本地SSD ~/KnowledgeBase(git操作只在此!)；Obsidian已从SeaDrive切到此路径。跨设备: 个人库走GitHub, 团队库走GitLab, 各自独立git仓库。已彻底放弃Seafile/SeaDrive(服务器10.250.8.32是远程SSO主机+依赖VPN+账号是...@auth.local非邮箱,稳定性太差)。一键同步: cd ~/KnowledgeBase && ./sync.sh ['msg'] = commit+push GitHub(无Seafile逻辑)。GitHub走ssh 443端口(已配core.sshCommand)。repo TheGoldenWave/Personal_knowledge_base.git。所有知识库cron已迁~/KnowledgeBase。gh CLI token失效(401)。gh CLI v2.92 ~/bin/gh;Multica CLI ~/bin/multica;~/bin in PATH。
§
Multica: ~/bin/multica v0.3.x。四工作区:GoldenWave/AI先锋团/直播课AI&数据/金波的知识库。Daemon launchd,env MULTICA_CLAUDE_PATH=/usr/local/bin/zcode。AI日报由金波的知识库workspace Autopilot 09:00生成。停摆查daemon.log grep TLS超时。账单不含CC/Codex/ZChat/Hermes。
§
公司基建：IPS+COS+zyb-auto-deploy(Next.js15+PG)。ZCode生态: 插件40款(code.zuoyebang.cc/plugins)，MCP网关9个(mcp.zuoyebang.cc,含outcall外呼/monitoring/devops)。MCP全Agent可用，插件大多ZCode专属。LLM代理: Anthropic兼容 openproxy.zuoyebang.cc Key=zyb-dd7090693300e1b2ff23a03717728cb0@bella。
§
Agent Config Studio: ~/Documents/MyProject/Zhiboke_Claw/src/agent-config-studio/. Next.js14+React18+Anthropic SDK. dev port 3456. 技术方案:docs/prd/agent-config-studio/TECH-DESIGN.md.
§
goldenwave.asia personal website project lives at `/Users/goldenwave/Documents/MyProject/goldenwave-asia`, GitHub repo `TheGoldenWave/goldenwave-asia`, remote uses SSH `git@github.com:TheGoldenWave/goldenwave-asia.git`.
§
模型配置(2026-06-25): Hermes=qwen3.7-max(coding-plan). CC: Opus→claude-opus-4-8(5x), Sonnet→qwen3.7-max(~1.5x), Haiku→gpt-5.4-mini(0.35x). Codex: gpt-5.5主, shell子agent同CC模型. 全走ccproxy.yukework.com. 完整模型清单见skill autonomous-coding-agents/references/codingplan-models.md. 改Hermes config.yaml需用python3脚本(patch工具拒绝写).
§
虾宝工厂API: 前端errNo=0，内部/zbrag/接口errNo=200。MCP Server: ~/Documents/MyProject/Zhiboke_Claw/src/zhibao-mcp/ (11 tools, TS)。