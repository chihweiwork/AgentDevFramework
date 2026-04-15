# Development Workspace

這是你的開發工作區，在本機使用 GSD/Claude Code 編輯，在 container 內測試執行。

## 目錄結構建議（根據專案需求自行調整）

```
workspace/
├── src/            # 主要程式碼
├── tests/          # 測試
├── scripts/        # 工具腳本
├── config/         # 配置文件
└── docs/           # 文檔
```

或者對於資料處理專案：
```
workspace/
├── data/           # 資料
├── src/            # 主要程式碼
├── notebooks/      # Jupyter notebooks
└── tests/          # 測試
```

## 開發流程

### 1. 在本機開發 (使用 GSD/Claude Code/IDE)

```bash
# 在專案根目錄
cd workspace

# 使用你喜歡的 IDE 編輯代碼
# 例如: VS Code, PyCharm, 或直接用 GSD
```

### 2. 在 Container 內測試

```bash
# 進入 container
docker exec -it agent-runtime bash

# 切換到 workspace
cd ~/workspace

# 執行測試
python3 src/your_script.py
```

### 3. 透過 Agent 工具執行

Agent 工具可以呼叫 workspace 的代碼：

**範例工具定義** (`code/your-agent/tool/run_task.json`):
```json
{
  "name": "run_task",
  "description": "Run a task from workspace",
  "command": "python3 /home/ubuntu/workspace/src/main.py {input}",
  "working_directory": "~/workspace",
  "input_schema": {
    "type": "object",
    "properties": {
      "input": {"type": "string"}
    }
  }
}
```

**在 Web UI 使用** (http://localhost:8765):
```
Use run_task with input "your data"
```

## Container 內的目錄結構

```
/home/ubuntu/
├── workspace/              # 🔗 ./workspace (你的開發區)
├── code/                   # 🔗 ./code (Agent 工具)
├── .openharness/          # 🔗 ./.openharness (配置)
└── web/                    # 🔗 ./web (Web UI)
```

## 優勢

- ✅ **即時同步**: 本機編輯立即反映到 container
- ✅ **IDE 支援**: 可用任何你喜歡的編輯器
- ✅ **版本控制**: 在本機 git commit/push
- ✅ **隔離環境**: Container 提供一致的執行環境
- ✅ **Agent 整合**: 工具可以呼叫你的業務代碼

## 注意事項

- 代碼修改會即時同步到 container
- 可以在本機 commit/push
- Agent 工具可以通過絕對路徑 `/home/ubuntu/workspace/...` 呼叫代碼
- 如果不想提交 workspace 內容到 git，在 `.gitignore` 取消註釋 `workspace/`
