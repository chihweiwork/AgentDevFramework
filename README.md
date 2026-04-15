# AgentDevFramework

**通用 AI Agent 開發框架** - 基於 OpenHarness + LiteLLM + WebSocket 架構

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![OpenHarness](https://img.shields.io/badge/OpenHarness-AI%20Agent-green)](https://docs.all-hands.dev)
[![LiteLLM](https://img.shields.io/badge/LiteLLM-Multi%20Model-orange)](https://docs.litellm.ai)

## ✨ 特點

- 🚀 **快速開始** - 一個命令建立完整 Agent
- 🌐 **Web 界面** - 即時流式輸出的聊天界面
- 🔧 **多模型支持** - Claude、GPT-4、本地模型
- 📦 **工具系統** - JSON Schema 驅動的工具定義
- 🐳 **容器化** - Docker Compose 一键部署

## 🚀 快速開始

```bash
# 1. 克隆專案
git clone <your-repo-url>
cd AgentDevFramework

# 2. 設定環境
cp .env.example .env
nano .env  # 填入 API keys

# 3. 建立新 Agent
./create-agent.sh my-first-agent

# 4. 啟動服務
./start.sh

# 5. 進入容器並啟動 Web Chat
docker exec -it agent-runtime bash
cd ~/web && python3 server.py

# 6. 訪問瀏覽器
# http://localhost:8765
```

## 📁 專案结構

```
AgentDevFramework/
├── .openharness/          # OpenHarness 設定
│   ├── agents/           # Agent 定義檔案
│   └── skills/           # Skills 定義
├── code/                  # Agent 程式碼目錄
│   └── agent-1/          # 单个 agent
│       ├── script/       # Python 腳本
│       └── tool/         # 工具定義 (JSON)
├── web/                   # Web UI
│   ├── server.py         # WebSocket 服務器
│   └── index.html        # Web 界面
├── docs/                  # 詳細檔案
├── docker-compose.yaml    # 服務編排
├── Dockerfile             # 容器建構
├── create-agent.sh        # 快速建立 Agent 腳本 ⭐
└── start.sh               # 快速啟動腳本
```

## 🛠️ 建立你的第一个 Agent

```bash
# 建立新 agent
./create-agent.sh my-data-agent

# 生成的结構：
code/my-data-agent/
├── script/
│   └── example_tool.py      # 工具實現
└── tool/
    └── example_tool.json    # 工具定義

.openharness/
├── agents/
│   └── my-data-agent.md     # Agent 檔案
└── skills/my-data-agent/
    └── example_skill.md     # Skill 檔案
```

## 🔧 架構說明

```
Browser (Web UI)
    ↓ WebSocket
Agent Runtime Container
    ├─ server.py (Starlette)
    ├─ OpenHarness Backend
    └─ Tools (JSON Schema 驅動)
    ↓ HTTP
LiteLLM Proxy
    ├─ Claude (AWS Bedrock)
    ├─ GPT-4 (OpenAI)
    └─ 本地模型
```

## 📚 檔案

- [快速開始指南](docs/QUICK_START.md) - 30秒快速上手
- [完整檔案](docs/README_FULL.md) - 詳細專案說明
- [使用範本](docs/TEMPLATE.md) - 手動建立 Agent 指南
- [Template 使用說明](docs/TEMPLATE_USAGE.md) - 如何使用本專案作為 Template
- [架構說明](docs/STRUCTURE.md) - 核心檔案與技術細節
- [內容清单](docs/CONTENTS.md) - 完整內容目錄
- [開發指南](docs/CLAUDE.md) - Claude Code 工作指南

## 🎯 常用命令

```bash
# 建立新 agent
./create-agent.sh agent-name

# 啟動服務
./start.sh

# 檢視日志
docker compose logs -f agent

# 重启服務
docker compose restart agent

# 進入容器
docker exec -it agent-runtime bash

# 測試工具
python3 code/agent-name/script/tool.py "input"
```

## 🎨 作為 Template 使用

如果你想基於此專案建立新的 Agent 系統：

```bash
# 使用快速開始腳本
cd /path/to/parent/directory
./AgentDevFramework/quick-start-template.sh MyNewProject

# 或手動複製
cp -r AgentDevFramework MyNewProject
cd MyNewProject
# 清理範例內容並開始開發
```

詳細說明請參閱：[Template 使用指南](docs/TEMPLATE_USAGE.md)

## ⚙️ 環境設定

編輯 `.env` 檔案：

```bash
# AWS Bedrock (for Claude)
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...

# LiteLLM
LITELLM_MASTER_KEY=sk-your-secret

# Database
POSTGRES_PASSWORD=your-password
```

## 🌟 範例

### 建立資料采集 Agent

```bash
./create-agent.sh data-collector
cd code/data-collector

# 編輯 script/example_tool.py 實現邏輯
# 編輯 tool/example_tool.json 定義接口

# 測試
python3 script/example_tool.py "test input"
```

### 在 Web UI 中使用

```
Use example_tool with input "test data"
```

## 🐛 故障排查

```bash
# 檢查服務状态
docker compose ps

# 檢查端口
curl http://localhost:8765/    # Web UI
curl http://localhost:4000/health  # LiteLLM

# 檢視日志
docker compose logs -f
```

## 📦 技術栈

- **OpenHarness** - AI Agent 執行时
- **LiteLLM** - LLM 代理服務器
- **Starlette** - 非同步 Web 框架
- **PostgreSQL** - 資料持久化
- **Docker** - 容器化部署

## 📄 License

MIT License

## 🤝 贡獻

欢迎提交 Issue 和 Pull Request！

---

**快速参考**：完整使用說明請參閱 [docs/QUICK_START.md](docs/QUICK_START.md)
