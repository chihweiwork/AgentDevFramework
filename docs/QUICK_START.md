# 🚀 Quick Start Guide

## 30秒快速開始

```bash
# 1. 設定環境
cp .env.example .env && nano .env

# 2. 啟動服務
./start.sh

# 3. 進入容器
docker exec -it agent-runtime bash

# 4. 啟動 Web Chat
cd ~/web && python3 server.py

# 5. 訪問瀏覽器
# http://localhost:8765
```

## 建立你的第一个 Agent

```bash
# 建立新 agent
./create-agent.sh my-first-agent

# 檢視生成的檔案
tree code/my-first-agent
```

生成的结构：
```
code/my-first-agent/
├── script/
│   └── example_tool.py      # 工具實現（Python）
└── tool/
    └── example_tool.json    # 工具定義（JSON Schema）

.openharness/
├── agents/
│   └── my-first-agent.md    # Agent 檔案
└── skills/my-first-agent/
    └── example_skill.md     # Skill 檔案
```

## 測試你的工具

```bash
# 本地測試
python3 code/my-first-agent/script/example_tool.py "test input"

# 在 Web UI 中測試
# "Use example_tool with input 'test input'"
```

## 目錄结构說明

```
AgentDevFramework/
├── workspace/                 # 🔥 你的開發工作區
│   ├── src/                  # ← 主要程式碼
│   ├── tests/                # ← 測試
│   └── ...                   # ← 根據需求自行調整
│
├── code/                      # ← Agent 工具定義
│   ├── agent-1/              # 範例 agent
│   └── my-agent/             # 你的 agent
│       ├── script/           # Python 腳本 (可呼叫 workspace/)
│       │   └── tool.py
│       └── tool/             # 工具定義
│           └── tool.json
│
├── .openharness/              # OpenHarness 設定
│   ├── agents/               # ← Agent 說明檔案
│   └── skills/               # ← Skills 定義
│
├── web/                       # Web UI (无需修改)
│   ├── index.html
│   └── server.py
│
├── docker-compose.yaml        # Docker 設定
├── Dockerfile                 # 映像檔建構
├── litellm-config.yaml        # LLM 設定
│
└── create-agent.sh            # ⭐ 快速建立 agent
```

## 💻 開發流程

### **推薦: 本機編輯 + Container 測試**

```
Host (本機)              Container
─────────────            ─────────────
用 GSD/IDE 編輯   ←→    即時同步測試
workspace/               ~/workspace/
code/                    ~/code/
```

**優勢:**
- ✅ 在本機用熟悉的 IDE 開發
- ✅ 修改即時同步到 container
- ✅ Container 提供一致的執行環境
- ✅ 可正常 git commit/push

## 工作流程程程

### 1️⃣ 建立 Agent
```bash
./create-agent.sh data-collector
```

### 2️⃣ 實現工具邏輯
編輯 `code/data-collector/script/example_tool.py`：

```python
#!/usr/bin/env python3
import sys
import json

def main():
    input_data = sys.argv[1]
    
    # 你的邏輯在这里
    result = {
        "status": "success",
        "result": f"Processed: {input_data}"
    }
    
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
```

### 3️⃣ 更新工具定義
編輯 `code/data-collector/tool/example_tool.json`：

```json
{
  "name": "collect_data",
  "description": "Collect data from source",
  "command": "python3 script/example_tool.py {source}",
  "working_directory": "~/code/data-collector",
  "input_schema": {
    "type": "object",
    "properties": {
      "source": {
        "type": "string",
        "description": "Data source URL or identifier"
      }
    },
    "required": ["source"]
  },
  "output_schema": {
    "type": "object",
    "properties": {
      "status": {"type": "string"},
      "result": {"type": "string"}
    }
  },
  "timeout": 120,
  "requires": ["python3"]
}
```

### 4️⃣ 測試工具
```bash
# 本地測試
python3 code/data-collector/script/example_tool.py "https://api.example.com"

# 在 Web UI 測試
# "Use collect_data with source 'https://api.example.com'"
```

### 5️⃣ 添加更多工具
```bash
# 在同一个 agent 中添加更多工具
cp code/data-collector/tool/example_tool.json code/data-collector/tool/process_data.json
cp code/data-collector/script/example_tool.py code/data-collector/script/process_data.py

# 編輯新檔案實現不同功能
```

## 常用命令

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

## 設定 API Keys

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

重启服務使設定生效：
```bash
docker compose restart agent
```

## 端口說明

| 端口 | 服務 | 用途 |
|------|------|------|
| 4000 | LiteLLM | LLM API 代理 |
| 8765 | Web UI | 聊天界面 |
| 5432 | PostgreSQL | 資料庫（容器内部） |

## 下一步

1. 📖 阅读 [TEMPLATE.md](TEMPLATE.md) 了解詳細用法
2. 📚 檢視 [README.md](README.md) 了解架構
3. 🤖 参考 [CLAUDE.md](CLAUDE.md) 学习開發技巧
4. 🏗️ 檢視 [STRUCTURE.md](STRUCTURE.md) 了解内部结构

## 需要帮助？

- 檢視 [TEMPLATE.md](TEMPLATE.md) 的故障排查章节
- 檢視 Docker 日志：`docker compose logs -f`
- 測試各服務健康状态：
  ```bash
  curl http://localhost:4000/health  # LiteLLM
  curl http://localhost:8765/        # Web UI
  ```

---

**提示**: 所有建立的 agent 程式碼都在 `code/` 目錄下，可以直接編輯。修改后无需重启，OpenHarness 会自動发现新的工具定義！
