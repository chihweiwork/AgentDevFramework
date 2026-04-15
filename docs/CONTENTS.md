# AgentDevFramework 內容清单

## 📊 檔案统计

| 类别 | 檔案数 | 总行数 |
|------|--------|--------|
| 檔案 | 3 | 1,122 |
| 設定 | 4 | 137 |
| 腳本 | 2 | 100 |
| 容器 | 2 | 205 |
| Web | 2 | 778 |
| 工具 | 2 | 53 |
| **总计** | **15** | **2,395** |

## 📁 完整檔案结构

```
AgentDevFramework/
├── 📄 檔案檔案 (1,122 行)
│   ├── CLAUDE.md (367 行)         # Claude Code 工作指南
│   ├── README.md (276 行)         # 專案說明檔案
│   └── STRUCTURE.md (479 行)      # 詳細架構說明
│
├── 🐳 Docker 設定 (205 行)
│   ├── docker-compose.yml (65 行) # 三服務編排
│   └── Dockerfile (140 行)        # 多阶段建構
│
├── ⚙️ 設定檔案 (72 行)
│   ├── litellm_config.yaml (8 行) # LLM 模型設定
│   ├── .env.example (14 行)       # 環境变量範本
│   └── .gitignore (50 行)         # Git 忽略规則
│
├── 🚀 腳本檔案 (100 行)
│   ├── start.sh (58 行)           # 快速啟動腳本
│   └── entrypoint.sh (42 行)      # 容器啟動腳本
│
├── 🌐 Web 界面 (778 行)
│   ├── web/
│   │   ├── index.html (580 行)   # Web UI 前端
│   │   └── server.py (198 行)    # WebSocket 服務器
│
└── 🔧 工作空间 (53 行)
    └── workspace/
        ├── tools/
        │   └── hello_world.json (36 行)  # 範例工具定義
        ├── scripts/
        │   └── hello_world.sh (17 行)    # 範例工具腳本
        └── .openharness/                  # OpenHarness 設定目錄
```

## 📝 檔案詳細說明

### 1. 核心檔案 (CLAUDE.md, README.md, STRUCTURE.md)

**CLAUDE.md** (367 行)
- Claude Code 工作指南
- 架構模式和通信协议
- 開發命令和除錯技巧
- 工具建立三步骤指南
- 常见陷阱和解决方案

**README.md** (276 行)
- 專案概述和特性
- 架構图和說明
- 快速開始步骤
- 設定說明
- 開發工作流程程
- 故障排查

**STRUCTURE.md** (479 行)
- 完整檔案清单
- 核心檔案詳細說明
- 使用流程
- 設定說明
- 常用命令
- 除錯技巧
- 開發建议

### 2. Docker 設定

**docker-compose.yml** (65 行)
```yaml
services:
  litellm:        # LiteLLM 代理 (port 4000)
  db:             # PostgreSQL 資料库
  agent:          # Agent 執行時 (port 8765)
networks:
  agent-network:  # Bridge 網路
volumes:
  db-data:        # 資料库持久化
```

**关键設定**:
- 三服務架構
- 挂载 `./workspace` 和 `./web`
- 環境变量從 `.env` 注入
- 自動重启策略

**Dockerfile** (140 行)
```dockerfile
# Stage 1: downloader
- 下载 CLI 工具: bat, fzf, rg, fd, eza, sd, codex, starship, opencli

# Stage 2: python-builder
- 建立 Python 3.12 venv
- 安裝 openharness-ai, graphifyy

# Stage 3: final
- 基於 ai-agent-dev:latest
- 安裝 Node.js 22.14.0 (via nvm)
- 安裝 Chromium
- 設定 ubuntu 用户 (uid=1000)
```

### 3. 設定檔案

**litellm_config.yaml** (8 行)
```yaml
model_list:
  - model_name: claude-sonnet
    litellm_params:
      model: us.anthropic.claude-sonnet-4-6
      aws_access_key_id: os.environ/AWS_ACCESS_KEY_ID
      aws_secret_access_key: os.environ/AWS_SECRET_ACCESS_KEY
      aws_region_name: us-west-2
```

**支持的模型提供商**:
- AWS Bedrock (Claude)
- OpenAI (GPT-4, GPT-3.5)
- Azure OpenAI
- Anthropic Direct API
- 本地模型 (Ollama, vLLM)

**.env.example** (14 行)
```bash
# AWS Bedrock 凭证
AWS_ACCESS_KEY_ID=your_aws_access_key_here
AWS_SECRET_ACCESS_KEY=your_aws_secret_key_here

# LiteLLM 設定
LITELLM_MASTER_KEY=sk-your-secret-key
UI_USERNAME=admin
UI_PASSWORD=your-password

# PostgreSQL 設定
POSTGRES_USER=admin
POSTGRES_PASSWORD=your-db-password
POSTGRES_DB=litellm
DATABASE_URL=postgresql://admin:password@db:5432/litellm
```

**.gitignore** (50 行)
- `.env` (敏感信息)
- `db-data/` (資料库資料)
- `container-home/` (容器挂载)
- Python 缓存和建構檔案
- IDE 設定檔案
- 系統临时檔案

### 4. 啟動腳本

**start.sh** (58 行)
```bash
功能:
- 檢查 .env 檔案是否存在
- 验证 Docker 是否執行
- 啟動所有服務 (docker compose up -d)
- 等待服務就绪
- 顯示訪問說明和后续步骤
```

**entrypoint.sh** (42 行)
```bash
容器啟動时執行:
- 載入 nvm (Node.js)
- 啟動 Chromium headless (port 9222)
- 啟動 opencli daemon
- 保持容器執行 (exec /bin/bash)
```

### 5. Web 界面

**web/server.py** (198 行)

**架構**: Starlette ASGI + WebSocket

**核心功能**:
- WebSocket endpoint (`/ws`)
- 管理 OpenHarness 子程序
- OHJSON 协议解析
- 三任务非同步模式:
  - `stdout_reader()`: OpenHarness → WebSocket
  - `stderr_reader()`: 錯誤日志
  - `ws_reader()`: WebSocket → OpenHarness

**命令列參數**:
```python
--port 8765                  # Web UI 端口
--host 0.0.0.0              # 监听地址
--cwd ~/workspace           # 工作目錄
--permission-mode default   # 权限模式
--model claude-sonnet       # LLM 模型
--debug                     # 除錯模式
```

**web/index.html** (580 行)

**技术栈**:
- Vanilla JavaScript (无建構步骤)
- WebSocket 客户端
- Markdown 渲染 (marked.js + DOMPurify)

**核心功能**:
- 实时 WebSocket 連線
- 流式文本渲染 (批處理: 256字符或33ms)
- 工具卡片展示 (可折叠輸入/輸出)
- 模态對话框 (权限请求、用户提问)
- 自動滚动管理 (检测用户是否向上滚动)
- 深色主题 (GitHub Dark 风格)

**WebSocket 事件类型**:
- `ready` - 后端就绪
- `assistant_delta` - 流式文本增量
- `tool_started` / `tool_completed` - 工具生命周期
- `permission_request` / `question_request` - 交互请求
- `error` / `shutdown` - 錯誤和终止

### 6. 工具系統

**workspace/tools/hello_world.json** (36 行)

```json
{
  "name": "hello_world",
  "description": "A simple example tool that echoes a message",
  "command": "bash scripts/hello_world.sh {message}",
  "working_directory": "~/workspace",
  "input_schema": {
    "type": "object",
    "properties": {
      "message": {
        "type": "string",
        "description": "Message to echo"
      }
    },
    "required": ["message"]
  },
  "output_schema": {
    "type": "object",
    "properties": {
      "status": {"type": "string", "enum": ["success", "error"]},
      "result": {"type": "string"},
      "timestamp": {"type": "string"}
    }
  },
  "timeout": 30,
  "depends_on": [],
  "requires": ["bash"]
}
```

**工具定義標準字段**:
- `name`: 工具标识符 (snake_case)
- `description`: 人类可读的描述
- `command`: Shell 命令範本 (支持 `{param}` 插值)
- `working_directory`: 執行路径
- `input_schema`: JSON Schema 輸入验证
- `output_schema`: JSON Schema 輸出验证
- `timeout`: 超时秒数
- `depends_on`: 依赖的其他工具 (DAG 调度)
- `requires`: 環境要求 (预檢查)

**workspace/scripts/hello_world.sh** (17 行)

```bash
#!/bin/bash
set -e  # 遇错即停

MESSAGE="${1:-Hello, World!}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 輸出 JSON 结果
cat <<EOF
{
  "status": "success",
  "result": "Echo: $MESSAGE",
  "timestamp": "$TIMESTAMP"
}
EOF
```

**工具腳本要求**:
- 必須輸出 JSON 到 stdout
- 使用 heredoc (`cat <<EOF`) 避免转义问题
- 建议加 `set -e` (遇错即停)
- 返回值包含 `status` 字段 (success/error)

## 🔄 工作流程程程

### 首次啟動

```bash
# 1. 設定環境变量
cp .env.example .env
nano .env  # 填入 API keys

# 2. 啟動所有服務
./start.sh

# 3. 進入容器
docker exec -it agent-runtime bash

# 4. 啟動 Web Chat
cd ~/web && python3 server.py

# 5. 訪問 Web UI
# http://localhost:8765
```

### 建立新工具

```bash
# 1. 建立工具定義
cat > workspace/tools/my_tool.json <<'EOF'
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
EOF

# 2. 建立工具腳本
cat > workspace/scripts/my_tool.sh <<'EOF'
#!/bin/bash
set -e
INPUT="$1"
echo "Processing: $INPUT"
cat <<EOFJ
{
  "status": "success",
  "result": "Processed: $INPUT"
}
EOFJ
EOF

# 3. 設定可執行权限
chmod +x workspace/scripts/my_tool.sh

# 4. 在 Web UI 中測試
# "Use my_tool with input 'test data'"
```

### 日常開發

```bash
# 檢視日志
docker compose logs -f agent

# 重启服務
docker compose restart agent

# 進入容器除錯
docker exec -it agent-runtime bash

# 測試工具腳本
bash ~/workspace/scripts/hello_world.sh "test"

# 檢查 OpenHarness
python3 -m openharness --version
```

## 🔍 关键技术点

### 1. OHJSON 协议

OpenHarness 輸出带 `OHJSON:` 前缀的 JSON 事件:
```
OHJSON:{"type":"assistant_delta","message":"Hello"}
OHJSON:{"type":"tool_started","tool_name":"hello_world"}
```

server.py 解析並转发到 WebSocket 客户端。

### 2. 三任务非同步模式

```python
async def ws_endpoint(websocket: WebSocket):
    # 啟動 OpenHarness 子程序
    proc = await asyncio.create_subprocess_exec(...)
    
    # 三个並发任务
    stdout_task = asyncio.create_task(stdout_reader())
    stderr_task = asyncio.create_task(stderr_reader())
    ws_task = asyncio.create_task(ws_reader())
    
    # 等待任意任务完成
    done, pending = await asyncio.wait(
        [stdout_task, stderr_task, ws_task],
        return_when=asyncio.FIRST_COMPLETED
    )
```

### 3. 工具依赖 DAG

使用 `depends_on` 字段建構依赖图:
```json
// collect.json
{"name": "collect", "depends_on": []}

// process.json
{"name": "process", "depends_on": ["collect"]}

// analyze.json
{"name": "analyze", "depends_on": ["process"]}
```

執行顺序: `collect → process → analyze`

### 4. 多阶段 Docker 建構

```dockerfile
Stage 1: downloader
  ├─ 下载 CLI 工具二进制
  └─ 輸出: /binaries/

Stage 2: python-builder
  ├─ 建立 Python venv
  └─ 輸出: /opt/venv/

Stage 3: final
  ├─ 複製 Stage 1 的二进制
  ├─ 複製 Stage 2 的 venv
  └─ 安裝 Node.js + Chromium
```

优势: 最终映像檔不包含建構工具，体积更小。

## 📊 端口和服務

| 服務 | 容器名 | 端口 | 用途 |
|------|--------|------|------|
| LiteLLM | litellm-proxy | 4000 | LLM API 代理 |
| PostgreSQL | agent-postgres-db | 5432 (内部) | 資料库 |
| Agent Runtime | agent-runtime | 8765 | Web UI + OpenHarness |
| Chrome CDP | (主机) | 9222 | OpenCLI 瀏覽器控制 |

## 🔧 環境要求

- Docker Engine 20.10+
- Docker Compose V2
- 8GB+ RAM
- 20GB+ 磁盘空间
- (可選) Chrome 瀏覽器 (用於 OpenCLI)

## 📚 核心依赖

**Python**:
- openharness-ai (Agent 執行時)
- graphifyy (图谱工具)
- starlette (ASGI 框架)
- uvicorn (ASGI 服務器)

**Node.js**:
- @jackwener/opencli (瀏覽器控制)

**CLI 工具**:
- bat, fzf, ripgrep, fd, eza, sd
- codex, starship
- opencli extension

**服務**:
- LiteLLM (LLM 代理)
- PostgreSQL 16 (資料库)
- Chromium (无头瀏覽器)

## 🎯 下一步開發方向

1. **CLI 工具** (`agentdev` 命令)
   - 專案初始化
   - 工具生成器
   - 開發服務器管理

2. **更多範例**
   - 資料采集 agent
   - 資料分析 agent
   - 自動化任务 agent

3. **專案範本**
   - basic 範本
   - web-chat 範本
   - data-pipeline 範本

4. **測試和 CI/CD**
   - 单元測試
   - 集成測試
   - GitHub Actions

5. **檔案完善**
   - API 参考
   - 最佳实践
   - 视频教程

## 🐛 已知限制

1. **server.py 非自動啟動**: 需要手動在容器内執行
2. **Dockerfile 依赖 ai-agent-dev:latest**: 需要预先存在的基础映像檔
3. **无热重载**: 修改 server.py 或 index.html 需要重启
4. **工具定義无验证**: 缺少 JSON Schema 验证工具

## 💡 设计哲学

- **简洁优先**: 避免过度抽象
- **约定大于設定**: 合理的預設值
- **容器化优先**: 開箱即用的開發環境
- **檔案驅動**: 清晰的架構說明
- **JSON Schema 驅動**: 类型安全的工具系統

---

**最后更新**: 2026-04-15
**版本**: 0.1.0
**維護者**: AgentDevFramework Team
