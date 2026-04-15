# GSD (Get Shit Done) 使用指南

## 在本機使用 GSD 開發此專案

### 快速開始

```bash
# 方法 1: 直接在專案目錄啟動
cd /path/to/your-project
gsd

# 方法 2: 使用專案啟動腳本
./start-gsd.sh
```

## GSD 自動限制說明

GSD 預設會自動限制在當前目錄：

✅ **可以做的:**
- 讀寫 `workspace/` 目錄的代碼
- 編輯 `code/` 目錄的 Agent 工具
- 修改配置文件
- 創建新文件和目錄

❌ **不會做的:**
- 不會訪問父目錄或其他專案
- 不會修改系統檔案
- 不會影響其他專案的代碼

## 專案配置

### `.gsd/config.json`

專案配置檔案，定義了：
- 專案名稱和根目錄
- 允許/禁止訪問的路徑
- 預設載入的上下文文件
- Agent 模型設定

### 允許的路徑

```json
{
  "allowedPaths": [
    "workspace",    // 你的開發代碼
    "code",         // Agent 工具
    ".openharness", // 配置
    "web",          // Web UI
    "docs"          // 文檔
  ]
}
```

### 禁止的路徑

```json
{
  "blockedPaths": [
    ".env",    // 環境變數（包含密鑰）
    ".git"     // Git 內部文件
  ]
}
```

## 使用場景

### 1. 開發 Workspace 代碼

```bash
gsd

# 在 GSD 中
> Create a new feature in workspace/src/feature.py
```

### 2. 創建 Agent 工具

```bash
gsd

# 在 GSD 中
> Create a new agent tool in code/ that calls workspace/src/feature.py
```

### 3. 更新文檔

```bash
gsd

# 在 GSD 中
> Update README.md with the new features I just added
```

## 與 Container 的關係

```
Host (本機)                    Container
─────────────                  ─────────────
GSD 編輯代碼            ←→    即時同步
workspace/                     ~/workspace/
code/                          ~/code/
  ↓                              ↓
git commit                     測試執行
```

**工作流程:**
1. 在本機用 GSD 編輯代碼（限制在專案內）
2. 代碼即時同步到 container
3. 在 container 測試執行
4. 在本機 commit 變更

## 安全性

- ✅ GSD 只能訪問專案目錄
- ✅ `.env` 被明確禁止訪問
- ✅ `.git` 內部文件被保護
- ✅ 不會影響其他專案

## 提示

1. **啟動位置很重要**: 在專案根目錄啟動 GSD
2. **檢查路徑**: GSD 會顯示當前工作目錄
3. **使用腳本**: `./start-gsd.sh` 確保在正確位置啟動
4. **查看配置**: 檢查 `.gsd/config.json` 確認限制設定

## 故障排查

### GSD 訪問了其他目錄？

```bash
# 確認在正確的目錄啟動
pwd
# 應該在專案根目錄

# 重新啟動 GSD
./start-gsd.sh
```

### 需要修改限制？

編輯 `.gsd/config.json` 的 `allowedPaths` 或 `blockedPaths`

### 想要更嚴格的限制？

```json
{
  "restrictions": {
    "allowedPaths": ["workspace"],  // 只允許 workspace
    "readOnly": true                 // 只讀模式
  }
}
```

## 自定義配置

當你使用此 template 創建新專案時：

1. **更新專案名稱**:
   ```json
   {
     "project": {
       "name": "YourProjectName"  // 改成你的專案名稱
     }
   }
   ```

2. **調整路徑限制**:
   根據需求添加或移除 `allowedPaths`

3. **更新上下文文件**:
   ```json
   {
     "agent": {
       "contextFiles": [
         "README.md",
         "your-custom-docs.md"
       ]
     }
   }
   ```

## 推薦設定

### 使用 direnv (可選)

如果你使用 direnv，`.envrc` 會自動載入環境變數：

```bash
# 安裝 direnv (如果還沒安裝)
# macOS: brew install direnv
# Ubuntu: apt install direnv

# 允許 direnv 載入此目錄的 .envrc
direnv allow

# 現在每次進入此目錄，環境變數會自動設定
```

### VS Code 整合 (可選)

在 `.vscode/settings.json` 添加：

```json
{
  "terminal.integrated.env.linux": {
    "GSD_PROJECT_ROOT": "${workspaceFolder}"
  }
}
```
