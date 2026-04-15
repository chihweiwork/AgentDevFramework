# AgentDevFramework Template

这是一个可重複使用的 OpenHarness Agent 開發工具包。

## 🚀 快速開始

### 1. 克隆或複製此範本

```bash
# 方式 A: 從 Git 克隆
git clone <your-repo-url> my-agent-project
cd my-agent-project

# 方式 B: 直接複製檔案夹
cp -r AgentDevFramework my-agent-project
cd my-agent-project
```

### 2. 設定環境

```bash
# 複製環境變數範本
cp .env.example .env

# 編輯 .env 檔案，填入你的 API keys
nano .env
```

### 3. 啟動服務

```bash
# 快速啟動（会自動檢查 Docker 和 .env）
./start.sh

# 或手動啟動
docker compose up -d
```

### 4. 進入容器並啟動 Web Chat

```bash
# 進入 agent 容器
docker exec -it agent-runtime bash

# 啟動 Web Chat 服務器
cd ~/web && python3 server.py
```

### 5. 訪問 Web UI

開啟瀏覽器訪問：http://localhost:8765

---

## 📂 目錄结构

```
AgentDevFramework/
├── .openharness/               # OpenHarness 設定
│   ├── agents/                # Agent 定義檔案
│   │   └── agent-1.md        # Agent 說明檔案
│   └── skills/                # Skills 定義
│       └── agent-1/          # 每个 agent 的 skills
│           └── hello_skill.md
│
├── code/                      # Agent 程式碼目錄
│   └── agent-1/              # 单个 agent
│       ├── script/           # Python 腳本
│       │   └── hello_world.py
│       └── tool/             # 工具定義 (JSON)
│           └── hello_world.json
│
├── web/                       # Web UI
│   ├── index.html            # 前端界面
│   └── server.py             # WebSocket 服務器
│
├── Dockerfile                 # 容器建構檔案
├── docker-compose.yaml        # 服務編排設定
├── litellm-config.yaml        # LLM 模型設定
├── .env.example               # 環境變數範本
├── .gitignore                 # Git 忽略规則
│
├── create-agent.sh            # 快速建立新 agent 腳本 ⭐
├── start.sh                   # 快速啟動腳本
├── entrypoint.sh              # 容器啟動腳本
│
├── TEMPLATE.md                # 本檔案（使用說明）
├── README.md                  # 專案說明
├── CLAUDE.md                  # Claude Code 指南
└── STRUCTURE.md               # 架構詳細說明
```

---

## 🔧 建立新 Agent

### 使用自動化腳本（推荐）

```bash
# 建立新 agent
./create-agent.sh my-data-agent

# 这会自動建立：
# - code/my-data-agent/script/example_tool.py
# - code/my-data-agent/tool/example_tool.json
# - .openharness/agents/my-data-agent.md
# - .openharness/skills/my-data-agent/example_skill.md
```

### 手動建立

#### 1. 建立目錄结构

```bash
mkdir -p code/my-agent/script
mkdir -p code/my-agent/tool
mkdir -p .openharness/agents
mkdir -p .openharness/skills/my-agent
```

#### 2. 建立工具定義 (`code/my-agent/tool/my_tool.json`)

```json
{
  "name": "my_tool",
  "description": "Tool description",
  "command": "python3 script/my_tool.py {input}",
  "working_directory": "~/code/my-agent",
  "input_schema": {
    "type": "object",
    "properties": {
      "input": {
        "type": "string",
        "description": "Input parameter"
      }
    },
    "required": ["input"]
  },
  "output_schema": {
    "type": "object",
    "properties": {
      "status": {"type": "string", "enum": ["success", "error"]},
      "result": {"type": "string"}
    }
  },
  "timeout": 60,
  "depends_on": [],
  "requires": ["python3"]
}
```

#### 3. 實現工具腳本 (`code/my-agent/script/my_tool.py`)

```python
#!/usr/bin/env python3
import sys
import json

def main():
    if len(sys.argv) < 2:
        result = {"status": "error", "result": "Input required"}
        print(json.dumps(result, indent=2))
        sys.exit(1)

    input_data = sys.argv[1]

    # Your logic here
    result = {
        "status": "success",
        "result": f"Processed: {input_data}"
    }

    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
```

```bash
chmod +x code/my-agent/script/my_tool.py
```

#### 4. 建立 Agent 檔案 (`.openharness/agents/my-agent.md`)

```markdown
# My Agent

Agent description.

## Purpose

What this agent does.

## Available Tools

- `my_tool`: Tool description

## Usage

\`\`\`
Use my_tool with input "test"
\`\`\`
```

#### 5. 測試工具

```bash
# 在容器内測試
python3 code/my-agent/script/my_tool.py "test input"

# 或在 Web UI 中測試
# "Use my_tool with input 'test input'"
```

---

## ⚙️ 設定說明

### 環境變數 (.env)

```bash
# AWS Bedrock (for Claude models)
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret

# LiteLLM Configuration
LITELLM_MASTER_KEY=sk-your-secret
UI_USERNAME=admin
UI_PASSWORD=your-password

# PostgreSQL Database
POSTGRES_USER=admin
POSTGRES_PASSWORD=your-db-password
POSTGRES_DB=litellm
DATABASE_URL=postgresql://admin:password@db:5432/litellm
```

### LLM 模型設定 (litellm-config.yaml)

```yaml
model_list:
  - model_name: claude-sonnet
    litellm_params:
      model: us.anthropic.claude-sonnet-4-6
      aws_access_key_id: os.environ/AWS_ACCESS_KEY_ID
      aws_secret_access_key: os.environ/AWS_SECRET_ACCESS_KEY
      aws_region_name: us-west-2
```

支持的模型：
- AWS Bedrock (Claude)
- OpenAI (GPT-4, GPT-3.5)
- Azure OpenAI
- Anthropic Direct API
- 本地模型 (Ollama, vLLM)

---

## 🛠️ 常用命令

### Docker 管理

```bash
# 檢視服務状态
docker compose ps

# 檢視日志
docker compose logs -f agent

# 重启服務
docker compose restart agent

# 重新建構
docker compose build --no-cache

# 停止所有服務
docker compose down

# 清理資料卷（⚠️ 会刪除資料庫資料）
docker compose down -v
```

### 容器内操作

```bash
# 進入容器
docker exec -it agent-runtime bash

# 啟動 Web Chat
cd ~/web && python3 server.py

# 測試工具
python3 ~/code/agent-1/script/hello_world.py "test"

# 檢視 OpenHarness 版本
python3 -m openharness --version
```

### 測試 API

```bash
# 測試 LiteLLM
curl http://localhost:4000/health

# 測試 Web UI
curl http://localhost:8765/

# 測試 PostgreSQL
docker exec agent-postgres-db pg_isready -U admin
```

---

## 🔍 工具開發最佳实践

### 1. 工具腳本必須輸出 JSON

```python
# ✅ 正确
result = {"status": "success", "result": "data"}
print(json.dumps(result, indent=2))

# ❌ 錯誤
print("Success!")  # 不是 JSON
```

### 2. 使用 JSON Schema 驗證

工具定義的 `input_schema` 和 `output_schema` 会自動驗證資料。

### 3. 錯誤處理

```python
try:
    # Your logic
    result = {"status": "success", "result": data}
except Exception as e:
    result = {"status": "error", "result": str(e)}
    sys.exit(1)
finally:
    print(json.dumps(result, indent=2))
```

### 4. 工具依赖

使用 `depends_on` 声明依赖：

```json
{
  "name": "analyze",
  "depends_on": ["collect", "process"]
}
```

執行顺序：`collect → process → analyze`

### 5. 超时設定

根据任务複雜度設定合理的 `timeout`：
- 簡單操作：30-60秒
- 資料處理：120-300秒
- 複雜分析：300-600秒

---

## 🎯 範例專案

### 資料采集 Agent

```bash
./create-agent.sh data-collector

# 編輯工具實現資料采集邏輯
# code/data-collector/script/collect_data.py
```

### 資料分析 Agent

```bash
./create-agent.sh data-analyzer

# 實現分析邏輯
# code/data-analyzer/script/analyze.py
```

### 自動化任务 Agent

```bash
./create-agent.sh task-automation

# 實現自動化邏輯
# code/task-automation/script/run_task.py
```

---

## 📝 檔案修改影响

| 修改的檔案 | 需要的操作 |
|------------|------------|
| `web/server.py` 或 `web/index.html` | 重启 server.py |
| `docker-compose.yaml` | `docker compose up -d` |
| `Dockerfile` | `docker compose build --no-cache` 后 `up -d` |
| `.env` | `docker compose restart agent` |
| `litellm-config.yaml` | `docker compose restart litellm` |
| `code/**/tool/*.json` | 无需重启（自動发现） |
| `code/**/script/*.py` | 无需重启（執行时載入） |

---

## 🐛 故障排查

### Web UI 無法連線

```bash
# 檢查服務状态
docker compose ps

# 檢查端口
curl http://localhost:8765/

# 檢視日志
docker compose logs -f agent
```

### LiteLLM API 錯誤

```bash
# 檢查 LiteLLM 日志
docker compose logs litellm

# 測試健康檢查
curl http://localhost:4000/health

# 驗證環境變數
docker exec litellm-proxy env | grep AWS
```

### OpenHarness 找不到工具

```bash
# 進入容器
docker exec -it agent-runtime bash

# 檢查工具檔案是否存在
ls -la ~/code/*/tool/*.json

# 測試工具腳本
python3 ~/code/agent-1/script/hello_world.py "test"
```

---

## 📚 更多檔案

- [README.md](README.md) - 專案概述和特性
- [CLAUDE.md](CLAUDE.md) - Claude Code 工作指南
- [STRUCTURE.md](STRUCTURE.md) - 詳細架構說明
- [CONTENTS.md](CONTENTS.md) - 完整內容清单

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 License

MIT License

---

**快速参考**

```bash
# 建立新專案
cp -r AgentDevFramework my-project && cd my-project

# 設定環境
cp .env.example .env && nano .env

# 建立新 agent
./create-agent.sh my-agent

# 啟動服務
./start.sh

# 進入容器
docker exec -it agent-runtime bash

# 啟動 Web Chat
cd ~/web && python3 server.py

# 訪問 UI
# http://localhost:8765
```
