# AgentDevFramework 專案结构說明

## 📁 完整檔案清单

```
AgentDevFramework/
├── docker-compose.yml          # Docker 服務編排設定
├── Dockerfile                  # 容器映像檔建構檔案
├── entrypoint.sh              # 容器啟動腳本
├── start.sh                   # 快速啟動腳本
├── .env.example               # 環境变量範本
├── .gitignore                 # Git 忽略檔案
├── litellm_config.yaml        # LiteLLM 模型設定
├── README.md                  # 專案說明檔案
├── STRUCTURE.md               # 本檔案
│
├── web/                       # Web 界面
│   ├── server.py             # WebSocket 服務器 (Starlette)
│   └── index.html            # Web UI 前端
│
└── workspace/                 # 工作目錄 (挂载到容器)
    ├── .openharness/         # OpenHarness 設定目錄
    ├── tools/                # 工具定義目錄
    │   └── hello_world.json # 範例工具定義
    └── scripts/              # 工具腳本目錄
        └── hello_world.sh   # 範例工具腳本
```

## 🔑 核心檔案說明

### 1. docker-compose.yml
**用途**: 定義和編排三个核心服務
- `db`: PostgreSQL 資料库
- `litellm`: LLM 代理服務器
- `agent`: Agent 執行時容器

**关键設定**:
- 網路: `agent-network` (bridge 模式)
- 端口: 
  - 4000: LiteLLM API
  - 8765: Web UI
- 卷挂载:
  - `./workspace` → `/home/ubuntu/workspace`
  - `./web` → `/home/ubuntu/web`

### 2. Dockerfile
**用途**: 建構 Agent 執行時映像檔

**三阶段建構**:
1. **downloader**: 下载 CLI 工具 (bat, fzf, rg, fd, eza, sd, codex, starship, opencli)
2. **python-builder**: 建構 Python venv (openharness-ai, graphifyy)
3. **final**: 组装最终映像檔

**关键特性**:
- 基於 `ai-agent-dev:latest` 或 `ubuntu:24.04`
- Python 3.12 + Node.js 22.14.0 (via nvm)
- 安裝 Chromium (用於 OpenCLI)
- 用户: `ubuntu` (uid=1000)

### 3. web/server.py
**用途**: WebSocket 网关服務器

**架構**:
```
Browser WebSocket ↔ Starlette Server ↔ OpenHarness 子程序
```

**三任务非同步模式**:
- `stdout_reader()`: 讀取 OpenHarness 輸出 → 转发到 WebSocket
- `stderr_reader()`: 讀取錯誤日志
- `ws_reader()`: 讀取 WebSocket 消息 → 发送到 OpenHarness stdin

**OHJSON 协议**:
- OpenHarness 輸出以 `OHJSON:` 前缀标记 JSON 事件
- 非 OHJSON 行作為日志輸出

### 4. web/index.html
**用途**: Web UI 前端

**核心功能**:
- 实时 WebSocket 連線
- 流式文本渲染 (批處理: 256字符或33ms)
- Markdown 渲染 (marked.js + DOMPurify)
- 工具卡片展示
- 模态對话框 (权限请求、用户提问)
- 自動滚动管理

**事件类型**:
- `ready`: 后端就绪
- `assistant_delta`: 流式文本增量
- `tool_started` / `tool_completed`: 工具生命周期
- `permission_request` / `question_request`: 交互请求
- `error` / `shutdown`: 錯誤和终止

### 5. litellm_config.yaml
**用途**: 設定 LLM 模型路由

**預設模型**: Claude Sonnet 4.6 (AWS Bedrock)

**支持的提供商**:
- AWS Bedrock
- OpenAI
- Azure OpenAI
- Anthropic
- 本地模型 (Ollama, vLLM)

### 6. workspace/tools/*.json
**用途**: 工具定義檔案 (JSON Schema 驅動)

**標準格式**:
```json
{
  "name": "tool_name",
  "description": "工具描述",
  "command": "bash scripts/tool.sh {param}",
  "working_directory": "~/workspace",
  "input_schema": { /* JSON Schema */ },
  "output_schema": { /* JSON Schema */ },
  "timeout": 60,
  "depends_on": ["other_tool"],
  "requires": ["bash", "jq"]
}
```

**关键字段**:
- `command`: 命令範本，支持參數插值 `{param}`
- `input_schema`: 輸入验证 (JSON Schema)
- `output_schema`: 輸出验证 (JSON Schema)
- `depends_on`: 依赖的其他工具 (DAG 调度)
- `requires`: 環境要求 (预檢查)
- `timeout`: 超时秒数

## 🚀 使用流程

### 1. 首次設定
```bash
# 1. 設定環境变量
cp .env.example .env
nano .env  # 填入 API keys

# 2. 啟動服務
./start.sh
# 或
docker compose up -d
```

### 2. 進入容器
```bash
docker exec -it agent-runtime bash
```

### 3. 啟動 Web Chat
```bash
cd ~/web
python3 server.py
```

### 4. 訪問 Web UI
瀏覽器開啟: http://localhost:8765

### 5. 建立自定義工具

**步骤 1**: 建立工具定義 `workspace/tools/my_tool.json`
```json
{
  "name": "my_tool",
  "description": "My custom tool",
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
  "requires": ["bash"]
}
```

**步骤 2**: 建立工具腳本 `workspace/scripts/my_tool.sh`
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

**步骤 3**: 設定可執行权限
```bash
chmod +x workspace/scripts/my_tool.sh
```

**步骤 4**: 在 Web UI 中使用
```
Use my_tool with input "test data"
```

## 🔧 設定說明

### 環境变量 (.env)

```bash
# AWS Bedrock (for Claude models)
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
DATABASE_URL=postgresql://admin:password@db:5432/litellm
```

### OpenHarness 設定 (workspace/.openharness/settings.json)

```json
{
  "model": "claude-sonnet",
  "permission_mode": "full_auto",
  "max_turns": 200,
  "memory_enabled": true
}
```

## 🛠️ 常用命令

### Docker 操作
```bash
# 檢視服務状态
docker compose ps

# 檢視日志
docker compose logs -f
docker compose logs -f agent

# 重启服務
docker compose restart agent

# 重新建構
docker compose build --no-cache

# 停止服務
docker compose down

# 清理卷
docker compose down -v
```

### 容器内操作
```bash
# 進入容器
docker exec -it agent-runtime bash

# 啟動 Web Chat
cd ~/web && python3 server.py

# 檢視工具列表
ls -la ~/workspace/tools/

# 測試工具腳本
bash ~/workspace/scripts/hello_world.sh "test"

# 檢查 OpenHarness
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

## 📊 架構图

```
┌─────────────────────────────────────────────────────────┐
│                      Browser                             │
│                    (Web UI)                              │
└────────────────────┬────────────────────────────────────┘
                     │ WebSocket (ws://localhost:8765/ws)
                     │
┌────────────────────▼────────────────────────────────────┐
│              Agent Runtime Container                     │
│  ┌─────────────────────────────────────────────────┐   │
│  │  web/server.py (Starlette + Uvicorn)            │   │
│  │  - WebSocket endpoint                            │   │
│  │  - OHJSON protocol parser                        │   │
│  └─────────────────┬───────────────────────────────┘   │
│                    │ stdin/stdout pipes                  │
│  ┌─────────────────▼───────────────────────────────┐   │
│  │  OpenHarness Backend (--backend-only)           │   │
│  │  - Tool execution engine                         │   │
│  │  - LLM interaction manager                       │   │
│  │  - Permission system                             │   │
│  └─────────────────┬───────────────────────────────┘   │
│                    │ HTTP (http://litellm:4000/v1)      │
└────────────────────┼────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              LiteLLM Proxy Container                     │
│  - OpenAI-compatible API                                 │
│  - Model routing                                         │
│  - Request logging                                       │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
         ▼           ▼           ▼
    ┌────────┐  ┌────────┐  ┌────────┐
    │ Claude │  │ GPT-4  │  │ Local  │
    │Bedrock │  │ OpenAI │  │ Models │
    └────────┘  └────────┘  └────────┘

┌─────────────────────────────────────────────────────────┐
│              PostgreSQL Container                        │
│  - LiteLLM request logs                                  │
│  - Model configuration                                   │
└─────────────────────────────────────────────────────────┘
```

## 🔍 除錯技巧

### 1. Web UI 無法連線
```bash
# 檢查 server.py 是否執行
docker exec agent-runtime ps aux | grep server.py

# 檢查端口
docker exec agent-runtime netstat -tlnp | grep 8765

# 手動啟動
docker exec -it agent-runtime bash
cd ~/web && python3 server.py --debug
```

### 2. LiteLLM API 錯誤
```bash
# 檢視日志
docker compose logs litellm

# 測試健康檢查
curl -v http://localhost:4000/health

# 測試模型列表
curl http://localhost:4000/models

# 檢查環境变量
docker exec litellm-proxy env | grep AWS
```

### 3. OpenHarness 问题
```bash
# 進入容器
docker exec -it agent-runtime bash

# 檢查版本
python3 -m openharness --version

# 測試執行
python3 -m openharness --backend-only --cwd ~/workspace

# 檢視設定
cat ~/.openharness/settings.json
```

### 4. 工具執行失败
```bash
# 手動測試工具腳本
bash ~/workspace/scripts/hello_world.sh "test"

# 檢查权限
ls -la ~/workspace/scripts/

# 檢視工具定義
cat ~/workspace/tools/hello_world.json | jq .
```

## 📝 開發建议

### 1. 工具開發最佳实践
- ✅ 使用 JSON Schema 验证輸入輸出
- ✅ 在腳本开头加 `set -e` (遇错即停)
- ✅ 使用 `cat <<EOF` 輸出 JSON (避免转义问题)
- ✅ 添加超时限制 (timeout 字段)
- ✅ 声明依赖 (requires 字段)

### 2. 錯誤處理
```bash
#!/bin/bash
set -e

INPUT="$1"

# 验证輸入
if [ -z "$INPUT" ]; then
    cat <<EOF
{
  "status": "error",
  "message": "Input parameter is required"
}
EOF
    exit 1
fi

# 业务邏輯
# ...

# 成功輸出
cat <<EOF
{
  "status": "success",
  "result": "$RESULT"
}
EOF
```

### 3. 依赖管理
使用 `depends_on` 建構工具链:
```json
{
  "name": "report",
  "depends_on": ["collect", "process", "analyze"]
}
```

DAG 執行顺序:
```
collect → process → analyze → report
```

## 🎯 下一步

1. **添加更多工具**: 在 `workspace/tools/` 建立新的工具定義
2. **集成外部 API**: 在腳本中调用 REST API
3. **資料持久化**: 使用資料库或檔案系統存储结果
4. **工作流程程編排**: 使用 `depends_on` 建立複雜的工作流程程
5. **自定義前端**: 修改 `web/index.html` 定制 UI

## 📚 参考资源

- [OpenHarness 檔案](https://docs.all-hands.dev)
- [LiteLLM 檔案](https://docs.litellm.ai)
- [Starlette 檔案](https://www.starlette.io/)
- [JSON Schema 规范](https://json-schema.org/)

## 💡 提示

- 修改工具定義后无需重启，OpenHarness 会自動載入
- 修改 server.py 或 index.html 需要重启 server.py
- 修改 docker-compose.yml 需要 `docker compose up -d` 重新載入
- 修改 Dockerfile 需要 `docker compose build` 重新建構
