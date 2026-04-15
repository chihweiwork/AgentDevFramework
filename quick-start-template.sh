#!/bin/bash
# 使用 AgentDevFramework Template 快速開始新專案
# Usage: ./quick-start-template.sh <new-project-name>

set -e

NEW_PROJECT=$1
TEMPLATE_DIR="AgentDevFramework"

if [ -z "$NEW_PROJECT" ]; then
    echo "❌ Error: Project name is required"
    echo "Usage: ./quick-start-template.sh <new-project-name>"
    echo ""
    echo "Example:"
    echo "  ./quick-start-template.sh MyDataPipeline"
    exit 1
fi

# Validate project name
if [[ ! "$NEW_PROJECT" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "❌ Error: Project name must contain only letters, numbers, hyphens, and underscores"
    exit 1
fi

echo "🚀 建立新專案: $NEW_PROJECT"
echo "基於 AgentDevFramework template"
echo "=================================="
echo ""

# Check if source template exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "❌ Error: Template directory '$TEMPLATE_DIR' not found"
    echo "請確保在包含 AgentDevFramework 目錄的位置執行此腳本"
    exit 1
fi

# Check if target directory already exists
if [ -d "$NEW_PROJECT" ]; then
    echo "❌ Error: Directory '$NEW_PROJECT' already exists"
    exit 1
fi

# 1. 複製專案
echo "📁 複製範本檔案..."
cp -r "$TEMPLATE_DIR" "$NEW_PROJECT"
cd "$NEW_PROJECT"

# 2. 清理範例 agents
echo "🧹 清理範例內容..."
rm -rf code/agent-1 code/test-agent
rm -f .openharness/agents/*.md
rm -rf .openharness/skills/*

# Ensure directories exist
mkdir -p .openharness/agents
mkdir -p .openharness/skills

# 3. 清理 git 歷史（如果存在）
if [ -d ".git" ]; then
    echo "🗑️  清理 Git 歷史..."
    rm -rf .git
fi

# 4. 設定環境變數
if [ ! -f ".env" ]; then
    echo "⚙️  建立環境設定..."
    cp .env.example .env
fi

echo ""
echo "✅ 新專案建立完成！"
echo ""
echo "📂 專案位置: $(pwd)"
echo ""
echo "🎯 接下來的步驟："
echo ""
echo "1️⃣  進入專案目錄："
echo "   cd $NEW_PROJECT"
echo ""
echo "2️⃣  編輯環境變數（填入 API keys）："
echo "   nano .env"
echo ""
echo "3️⃣  建立你的第一個 Agent："
echo "   ./create-agent.sh my-first-agent"
echo ""
echo "4️⃣  啟動服務："
echo "   ./start.sh"
echo ""
echo "5️⃣  進入容器："
echo "   docker exec -it agent-runtime bash"
echo ""
echo "6️⃣  啟動 Web UI（在容器內）："
echo "   cd ~/web && python3 server.py"
echo ""
echo "7️⃣  訪問瀏覽器："
echo "   http://localhost:8765"
echo ""
echo "📚 更多資訊請參考："
echo "   - docs/QUICK_START.md - 快速開始指南"
echo "   - docs/TEMPLATE_USAGE.md - Template 使用說明"
echo "   - docs/CLAUDE.md - 完整開發指南"
echo ""
