# 如何使用 AgentDevFramework 作為 Template

## 方法一：直接複製（最簡單）

### 1. 複製整個專案

```bash
# 複製專案到新目錄
cp -r AgentDevFramework MyNewProject
cd MyNewProject
```

### 2. 清理範例內容

```bash
# 刪除範例 agents
rm -rf code/agent-1
rm -rf code/test-agent

# 清理 .openharness 目錄
rm -rf .openharness/agents/*
rm -rf .openharness/skills/*
```

### 3. 設定環境

```bash
# 複製環境變數範本
cp .env.example .env

# 編輯 .env，填入你的 API keys
nano .env
```

### 4. 建立你的第一個 Agent

```bash
# 使用自動化腳本建立
./create-agent.sh my-first-agent

# 專案結構會變成：
# code/my-first-agent/
#   ├── script/example_tool.py
#   └── tool/example_tool.json
```

### 5. 啟動服務

```bash
# 快速啟動
./start.sh

# 進入容器
docker exec -it agent-runtime bash

# 啟動 Web UI
cd ~/web && python3 server.py

# 訪問瀏覽器
# http://localhost:8765
```

---

## 方法二：GitHub Template（推荐用於團隊）

### 1. 建立 GitHub Repository Template

```bash
# 初始化 git（如果還沒有）
git init
git add .
git commit -m "Initial commit: AgentDevFramework template"

# 推送到 GitHub
git remote add origin https://github.com/your-username/AgentDevFramework.git
git push -u origin main
```

### 2. 在 GitHub 上設定為 Template

1. 進入你的 GitHub repository 頁面
2. 點擊 **Settings**
3. 勾選 **Template repository** 選項

### 3. 從 Template 建立新專案

```bash
# 使用 GitHub CLI
gh repo create my-new-project --template your-username/AgentDevFramework

# 或在 GitHub 網頁上點擊 "Use this template" 按鈕
```

---

## 方法三：作為 Git Submodule（進階）

適合需要保持框架更新的場景。

```bash
# 在你的專案中加入 AgentDevFramework
git submodule add https://github.com/your-username/AgentDevFramework.git framework

# 目錄結構：
# my-project/
# ├── framework/           # AgentDevFramework submodule
# │   ├── web/
# │   ├── Dockerfile
# │   └── ...
# └── agents/              # 你的 agents 程式碼
#     └── my-agent/
```

---

## 清理檢查清单

使用 template 前，建議清理以下內容：

### ✅ 必須清理

- [ ] 刪除範例 agents：`code/agent-1/`, `code/test-agent/`
- [ ] 清空 `.openharness/agents/`
- [ ] 清空 `.openharness/skills/`
- [ ] 編輯 `.env` 填入你的 API keys

### ⚠️ 可選清理

- [ ] 更新 `README.md` 專案名稱和描述
- [ ] 更新 `litellm-config.yaml` 選擇你要的模型
- [ ] 修改 `docker-compose.yaml` 的 container 名稱

### 📚 保留檔案

- ✅ 保留 `docs/` 所有檔案（開發參考）
- ✅ 保留 `web/` 目錄（Web UI）
- ✅ 保留 `create-agent.sh`（建立 agent 工具）
- ✅ 保留 `start.sh`（快速啟動腳本）
- ✅ 保留 `Dockerfile`, `docker-compose.yaml`
- ✅ 保留 `.gitignore`

---

## 快速開始範本

複製這段程式碼建立新專案：

```bash
#!/bin/bash
# 使用 AgentDevFramework Template 快速開始

# 1. 複製專案
cp -r AgentDevFramework MyNewProject
cd MyNewProject

# 2. 清理範例
rm -rf code/agent-1 code/test-agent
rm -rf .openharness/agents/* .openharness/skills/*

# 3. 設定環境
cp .env.example .env
echo "✅ 已建立 .env 檔案，請編輯填入 API keys"

# 4. 建立第一個 agent
./create-agent.sh my-first-agent

# 5. 顯示後續步驟
echo ""
echo "🎉 新專案建立完成！"
echo ""
echo "接下來的步驟："
echo "1. 編輯 .env 填入你的 API keys"
echo "2. 執行 ./start.sh 啟動服務"
echo "3. docker exec -it agent-runtime bash"
echo "4. cd ~/web && python3 server.py"
echo "5. 訪問 http://localhost:8765"
```

將上面的腳本存為 `quick-start-template.sh`，設定可執行權限：

```bash
chmod +x quick-start-template.sh
./quick-start-template.sh
```

---

## 客製化建议

### 修改專案名稱

編輯 `docker-compose.yaml`：

```yaml
services:
  litellm:
    container_name: my-project-litellm  # 改這裡
  db:
    container_name: my-project-db       # 改這裡
  agent:
    container_name: my-project-runtime  # 改這裡
```

編輯 `README.md`：

```markdown
# MyNewProject

基於 AgentDevFramework 建立的 AI Agent 專案
```

### 修改 LLM 模型

編輯 `litellm-config.yaml`：

```yaml
model_list:
  # 使用 OpenAI GPT-4
  - model_name: gpt-4
    litellm_params:
      model: gpt-4
      api_key: os.environ/OPENAI_API_KEY

  # 使用本地 Ollama
  - model_name: llama3
    litellm_params:
      model: ollama/llama3
      api_base: http://localhost:11434
```

### 修改 Web UI 端口

編輯 `docker-compose.yaml`：

```yaml
agent:
  ports:
    - "8080:8765"  # 改為 8080
```

---

## 常見使用場景

### 場景 1：資料處理 Pipeline

```bash
./create-agent.sh data-collector
./create-agent.sh data-processor
./create-agent.sh data-analyzer
./create-agent.sh report-generator

# 建立工具依賴鏈：
# collect → process → analyze → report
```

### 場景 2：多語言翻譯系統

```bash
./create-agent.sh text-extractor
./create-agent.sh translator
./create-agent.sh quality-checker

# 工具流程：
# extract → translate → check
```

### 場景 3：自動化測試框架

```bash
./create-agent.sh test-generator
./create-agent.sh test-runner
./create-agent.sh result-analyzer

# 工具流程：
# generate → run → analyze
```

---

## 檔案結構參考

使用 template 後的理想結構：

```
MyNewProject/
├── code/
│   ├── data-collector/
│   │   ├── script/
│   │   │   ├── fetch_api.py
│   │   │   └── save_data.py
│   │   └── tool/
│   │       ├── fetch_api.json
│   │       └── save_data.json
│   ├── data-processor/
│   │   └── ...
│   └── report-generator/
│       └── ...
├── .openharness/
│   ├── agents/
│   │   ├── data-collector.md
│   │   ├── data-processor.md
│   │   └── report-generator.md
│   └── skills/
│       └── ...
├── web/
├── docs/
├── docker-compose.yaml
├── Dockerfile
├── .env
└── README.md
```

---

## 故障排查

### 問題 1：範例 agents 殘留

**症狀**：Web UI 中仍顯示 hello_world 工具

**解決**：
```bash
# 確認已刪除
ls -la code/
ls -la .openharness/agents/

# 重啟服務
docker compose restart agent
```

### 問題 2：.env 未設定

**症狀**：LiteLLM 401 錯誤

**解決**：
```bash
# 檢查 .env 是否存在
cat .env

# 確認必要的環境變數
grep AWS_ACCESS_KEY_ID .env
grep LITELLM_MASTER_KEY .env

# 重啟服務使生效
docker compose restart agent litellm
```

### 問題 3：端口衝突

**症狀**：`bind: address already in use`

**解決**：
```bash
# 查看佔用的端口
sudo lsof -i :8765
sudo lsof -i :4000

# 修改 docker-compose.yaml 的端口
# 或停止佔用端口的程序
```

---

## 最佳實踐

### 1. 版本控制

```bash
# 初始化 git
git init

# 確保 .env 不被追蹤
grep ".env" .gitignore  # 應該要有這行

# 提交初始版本
git add .
git commit -m "Initial commit from AgentDevFramework template"
```

### 2. 團隊協作

建立 `.github/workflows/test.yml`：

```yaml
name: Test Agents

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Test all agent scripts
        run: |
          find code -name "*.py" -path "*/script/*" -exec python3 {} "test" \;
```

### 3. 檔案管理

```bash
# 為每個 agent 建立 README
code/my-agent/README.md

# 內容範例：
# # My Agent
# 
# ## Purpose
# ...
# 
# ## Tools
# - tool1: description
# 
# ## Dependencies
# - python3
# - requests
```

---

## 進階客製化

### 添加新的 CLI 工具到容器

編輯 `Dockerfile`：

```dockerfile
# Stage 1: downloader
RUN wget https://github.com/your-tool/releases/download/v1.0/tool \
    -O /tmp/binaries/tool && chmod +x /tmp/binaries/tool
```

### 添加 Python 套件

編輯 `Dockerfile`：

```dockerfile
# Stage 2: python-builder
RUN pip install --no-cache-dir \
    openharness-ai \
    graphifyy \
    your-package-here
```

### 客製化 Web UI

編輯 `web/index.html`：

```html
<!-- 修改標題 -->
<title>My Custom Agent System</title>

<!-- 修改主題顏色 -->
<style>
  :root {
    --primary-color: #your-color;
  }
</style>
```

---

## 參考資源

- [CLAUDE.md](CLAUDE.md) - 開發指南
- [QUICK_START.md](QUICK_START.md) - 快速開始
- [TEMPLATE.md](TEMPLATE.md) - 使用範本
- [STRUCTURE.md](STRUCTURE.md) - 架構說明

---

## 取得幫助

如果遇到問題：

1. 檢查 `docs/CLAUDE.md` 的「Common Pitfalls」章節
2. 查看 Docker 日志：`docker compose logs -f`
3. 測試服務健康：
   ```bash
   curl http://localhost:4000/health  # LiteLLM
   curl http://localhost:8765/        # Web UI
   ```

---

**祝你使用愉快！** 🚀
