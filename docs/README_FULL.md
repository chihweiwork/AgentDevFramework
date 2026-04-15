# AgentDevFramework

通用 AI Agent 開發框架，基於 OpenHarness + LiteLLM + WebSocket 架構。

## Features

- 🚀 **快速啟動** - Docker Compose 一键部署
- 🌐 **Web 界面** - 即時流式輸出的聊天界面
- 🔧 **多模型支持** - 透過 LiteLLM 支持 Claude, GPT-4, 本地模型
- 📦 **工具系統** - JSON Schema 驅動的工具定義
- 🐳 **容器化** - 開箱即用的開發環境

## Architecture

```
┌─────────────┐
│   Browser   │
│  (Web UI)   │
└──────┬──────┘
       │ WebSocket
       ↓
┌─────────────────────────────────┐
│  Agent Runtime Container        │
│  ┌──────────────────────────┐  │
│  │  server.py (Starlette)   │  │
│  │  WebSocket Gateway       │  │
│  └───────────┬──────────────┘  │
│              │ stdin/stdout     │
│              ↓                  │
│  ┌──────────────────────────┐  │
│  │  OpenHarness Backend     │  │
│  │  (--backend-only mode)   │  │
│  └───────────┬──────────────┘  │
└──────────────┼──────────────────┘
               │ HTTP
               ↓
┌─────────────────────────────────┐
│  LiteLLM Proxy                  │
│  (OpenAI-compatible API)        │
└───────────┬─────────────────────┘
            │
            ├─→ Claude (AWS Bedrock)
            ├─→ GPT-4 (OpenAI)
            └─→ Local Models

┌─────────────────────────────────┐
│  PostgreSQL Database            │
│  (LiteLLM logs & config)        │
└─────────────────────────────────┘
```

## Quick Start

### 1. Prerequisites

- Docker & Docker Compose
- (可選) Chrome 瀏覽器用於 OpenCLI

### 2. Clone and Configure

```bash
git clone <your-repo>
cd AgentDevFramework

# 複製環境變數範本
cp .env.example .env

# 編輯 .env 填入你的 API keys
nano .env
```

### 3. Start Services

```bash
# 啟動所有服務
docker compose up -d

# 檢視日志
docker compose logs -f

# 進入 agent 容器
docker exec -it agent-runtime bash
```

### 4. Access Web UI

開啟瀏覽器訪問：http://localhost:8765

### 5. Start Web Chat Server

在容器内執行：

```bash
cd ~/web
python3 server.py
```

然後重新整理瀏覽器即可使用。

## Project Structure

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
│   └── index.html        # Web UI
├── docker-compose.yaml    # 服務編排
├── Dockerfile             # 容器建構
├── litellm-config.yaml    # LLM 模型設定
├── .env.example           # 環境變數範本
├── create-agent.sh        # 快速建立新 agent ⭐
└── start.sh               # 快速啟動腳本
```

## Configuration

### Environment Variables (.env)

```bash
# AWS Bedrock (for Claude)
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret

# LiteLLM
LITELLM_MASTER_KEY=sk-your-secret
UI_USERNAME=admin
UI_PASSWORD=your-password

# PostgreSQL
POSTGRES_USER=admin
POSTGRES_PASSWORD=your-db-password
POSTGRES_DB=litellm
```

### LiteLLM Models (litellm_config.yaml)

```yaml
model_list:
  - model_name: claude-sonnet
    litellm_params:
      model: us.anthropic.claude-sonnet-4-6
      aws_access_key_id: os.environ/AWS_ACCESS_KEY_ID
      aws_secret_access_key: os.environ/AWS_SECRET_ACCESS_KEY
      aws_region_name: us-west-2
```

支持的模型提供商：
- AWS Bedrock (Claude)
- OpenAI (GPT-4, GPT-3.5)
- Azure OpenAI
- Anthropic
- 本地模型 (Ollama, vLLM)

## Quick Agent Creation

使用自動化腳本快速建立新 agent：

```bash
# 建立新 agent
./create-agent.sh my-data-agent

# 这会自動生成：
# - code/my-data-agent/script/example_tool.py
# - code/my-data-agent/tool/example_tool.json
# - .openharness/agents/my-data-agent.md
# - .openharness/skills/my-data-agent/example_skill.md
```

## Development Workflow

### 1. 建立新工具

在 `workspace/tools/` 建立 JSON 定義檔案：

```json
{
  "name": "my_tool",
  "description": "Tool description",
  "command": "bash scripts/my_tool.sh {input}",
  "input_schema": {
    "type": "object",
    "properties": {
      "input": {"type": "string"}
    },
    "required": ["input"]
  },
  "output_schema": {
    "type": "object",
    "properties": {
      "status": {"type": "string"},
      "result": {"type": "string"}
    }
  },
  "timeout": 60,
  "depends_on": [],
  "requires": ["bash"]
}
```

### 2. 實現工具腳本

在 `workspace/scripts/` 建立腳本：

```bash
#!/bin/bash
INPUT="$1"

# Your logic here
echo "Processing: $INPUT"

# Output JSON
cat <<EOF
{
  "status": "success",
  "result": "Processed: $INPUT"
}
EOF
```

### 3. 在 Web UI 中測試

```
Use my_tool with input "test"
```

## Useful Commands

```bash
# 檢視服務状态
docker compose ps

# 檢視日志
docker compose logs -f agent

# 重启服務
docker compose restart agent

# 重新建構映像檔
docker compose build --no-cache

# 停止所有服務
docker compose down

# 清理資料卷
docker compose down -v
```

## Troubleshooting

### Web UI 無法連線

檢查服務是否啟動：
```bash
docker compose ps
curl http://localhost:8765/
```

### LiteLLM API 錯誤

檢查 API keys 是否正确：
```bash
docker compose logs litellm
```

測試 LiteLLM：
```bash
curl http://localhost:4000/health
```

### OpenHarness 無法啟動

進入容器檢查：
```bash
docker exec -it agent-runtime bash
python3 -m openharness --version
```

## License

MIT

## Credits

基於以下專案：
- [OpenHarness](https://github.com/All-Hands-AI/OpenHarness) - AI Agent 執行时
- [LiteLLM](https://github.com/BerriAI/litellm) - LLM 代理
- [Starlette](https://www.starlette.io/) - 非同步 Web 框架
