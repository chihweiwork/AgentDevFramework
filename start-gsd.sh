#!/bin/bash
# 啟動 GSD 並限制在當前專案

# 確保在專案根目錄
cd "$(dirname "$0")"

# 顯示當前工作目錄
echo "Starting GSD in project: $(pwd)"
echo "GSD will be restricted to this directory and its subdirectories."
echo ""

# 啟動 GSD
# GSD 會自動限制在當前目錄
gsd

# 或者如果你想指定特定的配置
# gsd --config .gsd/config.json
