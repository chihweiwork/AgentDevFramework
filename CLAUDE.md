# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案概述

AgentDevFramework 是一個通用 AI Agent 開發框架，基於 OpenHarness + LiteLLM + WebSocket 架構。核心設計是透過 JSON Schema 定義工具，讓 Agent 能夠執行自定義的 Python 腳本來完成各種任務。

## 核心架構

```
Browser (Web UI)
    ↓ WebSocket (port 8765)
web/server.py (Starlette)
    ↓ spawns subprocess
OpenHarness Backend (--backend-only)
    ↓ reads tools from
code/{agent-name}/tool/*.json
    ↓ executes
code/{agent-name}/script/*.py
    ↓ HTTP requests
LiteLLM Proxy (port 4000)
    ↓ AWS Bedrock API
Claude / GPT-4 / 本地模型
```

**關鍵設計**：
- `web/server.py` 透過 WebSocket 接收瀏覽器請求，為每個連接 spawn 一個獨立的 `openharness --backend-only` subprocess
- OpenHarness 從 `.openharness/agents/*.md` 讀取 agent 定義，從 `code/{agent}/tool/*.json` 載入工具
- 工具執行時，OpenHarness 在容器內 `cd ~/code/{agent}` 然後執行 JSON 中定義的 `command`
- LiteLLM 作為統一的 OpenAI-compatible API gateway，支援多種 LLM 提供商

## 開發環境設定

### 初次設置

```bash
# 1. 複製環境變數範本
cp .env.example .env

# 2. 編輯 .env 填入必要的 API keys
# - AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (for Bedrock Claude)
# - LITELLM_MASTER_KEY (LiteLLM 的認證 key)
# - POSTGRES_PASSWORD (資料庫密碼)

# 3. 啟動所有服務
./start.sh

# 4. 進入 agent 容器
docker exec -it agent-runtime bash

# 5. 啟動 Web Chat 服務器 (在容器內)
cd ~/web && python3 server.py

# 6. 瀏覽器訪問
open http://localhost:8765
```

### 快速建立新 Agent

```bash
# 使用自動化腳本 (推薦)
./create-agent.sh my-agent-name

# 生成的檔案結構：
# code/my-agent-name/
#   script/example_tool.py      # 工具實現
#   tool/example_tool.json      # 工具 JSON Schema 定義
# .openharness/
#   agents/my-agent-name.md     # Agent 文檔
#   skills/my-agent-name/       # Skills 定義

# 測試工具
python3 code/my-agent-name/script/example_tool.py "test input"
```

## 工具系統 (Tool System)

工具定義分為兩個部分：

### 1. JSON Schema 定義 (`code/{agent}/tool/*.json`)

```json
{
  "name": "tool_name",
  "description": "工具描述",
  "command": "python3 script/tool.py {param1} {param2}",
  "working_directory": "~/code/{agent-name}",
  "input_schema": {
    "type": "object",
    "properties": {
      "param1": {"type": "string", "description": "參數說明"}
    },
    "required": ["param1"]
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

**重要**：
- `command` 中的 `{param}` 會被替換為 input_schema 中定義的參數值
- `working_directory` 相對於容器內 ubuntu user 的 home (`/home/ubuntu`)
- OpenHarness 會在執行前 cd 到 working_directory

### 2. Python 腳本實現 (`code/{agent}/script/*.py`)

```python
#!/usr/bin/env python3
import sys
import json

def main():
    # 從 sys.argv 讀取參數
    input_data = sys.argv[1] if len(sys.argv) > 1 else ""
    
    # 執行邏輯
    result = process(input_data)
    
    # 輸出必須是 JSON，符合 output_schema
    print(json.dumps({
        "status": "success",
        "result": result
    }, indent=2))

if __name__ == "__main__":
    main()
```

**注意**：
- 腳本必須輸出 JSON 到 stdout
- JSON 格式需符合工具定義中的 `output_schema`
- 錯誤處理應返回 `{"status": "error", "result": "error message"}`

## Docker 服務

### 服務說明

- **litellm** (port 4000): LLM 代理服務器，提供 OpenAI-compatible API
- **db** (postgres): 儲存 LiteLLM 的日誌和配置
- **agent**: OpenHarness runtime + Web UI

### 常用 Docker 命令

```bash
# 啟動所有服務
docker compose up -d

# 查看日誌
docker compose logs -f agent
docker compose logs -f litellm

# 重啟特定服務
docker compose restart agent

# 停止所有服務
docker compose down

# 重新建構映像 (修改 Dockerfile 後)
docker compose build --no-cache agent

# 進入容器
docker exec -it agent-runtime bash

# 檢查服務狀態
docker compose ps
curl http://localhost:4000/health  # LiteLLM
curl http://localhost:8765/        # Web UI
```

## 目錄結構與掛載點

容器內的目錄對應：

```
Host                          → Container
./workspace                   → /home/ubuntu/workspace (WORKDIR)
./code                        → /home/ubuntu/code
./.openharness                → /home/ubuntu/.openharness
./web                         → /home/ubuntu/web
```

**開發時注意**：
- 在 host 修改 `code/` 或 `.openharness/` 會立即反映在容器內
- Web server 需要重啟才能載入新的 agent 定義
- 工具腳本修改後直接生效（下次調用時）

## LiteLLM 配置

編輯 `litellm-config.yaml` 來新增模型：

```yaml
model_list:
  - model_name: claude-sonnet
    litellm_params:
      model: us.anthropic.claude-sonnet-4-6
      aws_access_key_id: os.environ/AWS_ACCESS_KEY_ID
      aws_secret_access_key: os.environ/AWS_SECRET_ACCESS_KEY
      aws_region_name: us-west-2
```

修改後需重啟 litellm 服務：
```bash
docker compose restart litellm
```

## Web UI 系統

`web/server.py` 實現了 WebSocket <-> OpenHarness 的橋接：

1. 瀏覽器透過 WebSocket 連接到 `/ws`
2. Server 為每個連接 spawn subprocess: `python3 -m openharness --backend-only`
3. Server 轉發：
   - WebSocket messages → subprocess stdin
   - subprocess stdout (OHJSON: 開頭) → WebSocket
4. OpenHarness 的流式輸出透過 OHJSON 協議即時顯示在網頁

**啟動參數**：
```bash
python3 server.py --port 8765 --cwd /home/ubuntu/workspace --permission-mode default
```

## Agent 定義檔案

`.openharness/agents/{agent-name}.md` 定義 agent 的用途和可用工具：

```markdown
# My Agent

描述 agent 的用途

## Purpose

詳細說明這個 agent 的目的

## Available Tools

- `tool_name`: 工具描述

## Usage

示範如何在對話中使用工具
```

OpenHarness 會讀取這些 markdown 檔案來生成 agent 的 system prompt。

## 故障排查

### Web UI 無法連接

```bash
# 檢查服務是否運行
docker compose ps

# 檢查 Web server 日誌
docker compose logs -f agent

# 手動啟動 Web server (在容器內)
docker exec -it agent-runtime bash
cd ~/web && python3 server.py --debug
```

### 工具執行失敗

```bash
# 進入容器測試
docker exec -it agent-runtime bash
cd ~/code/{agent-name}
python3 script/tool.py "test input"

# 檢查 working_directory 是否正確
# 檢查 JSON 輸出格式是否符合 output_schema
# 檢查檔案權限 (chmod +x)
```

### LiteLLM API 錯誤

```bash
# 檢查 LiteLLM 健康狀態
curl http://localhost:4000/health

# 查看 LiteLLM 日誌
docker compose logs -f litellm

# 驗證環境變數
docker exec litellm-proxy env | grep AWS
```

### 資料庫連接問題

```bash
# 檢查 PostgreSQL 狀態
docker exec agent-postgres-db pg_isready -U admin

# 查看資料庫日誌
docker compose logs -f db
```

## 開發最佳實踐

1. **測試工具**：先在容器內直接執行 Python 腳本測試，確認輸出格式正確
2. **JSON Schema**：input/output schema 要與實際腳本的參數和輸出一致
3. **錯誤處理**：Python 腳本應該 catch 所有 exception 並返回 error status
4. **超時設置**：根據工具的實際執行時間設定合理的 timeout
5. **依賴管理**：如需額外的 Python 套件，修改 Dockerfile 並重新 build
6. **日誌記錄**：使用 stderr 輸出 debug 訊息，stdout 保留給 JSON 結果

## 擴展系統

### 添加新的 Python 套件

編輯 `Dockerfile` 的 python-builder stage：

```dockerfile
RUN pip install openharness-ai graphifyy your-new-package
```

然後重新建構：
```bash
docker compose build --no-cache agent
docker compose up -d
```

### 添加新的 CLI 工具

在 `Dockerfile` 的 downloader stage 添加下載邏輯，然後在 final stage COPY 到 `/usr/local/bin/`

### 切換 LLM 模型

在呼叫 OpenHarness 時指定 model：
```bash
python3 -m openharness --model claude-sonnet
```

或在 `web/server.py` 啟動時設定 `--model` 參數。
