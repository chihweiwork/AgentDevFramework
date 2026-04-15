#!/bin/bash
# Entrypoint script for Agent Runtime Container

set -e

echo "Starting Agent Runtime Container..."

# Source nvm for Node.js
export NVM_DIR="/home/ubuntu/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Start Chromium in headless mode (for OpenCLI)
if [ -d "/opt/chromium" ]; then
    CHROME_BIN=$(find /opt/chromium -name chrome -type f | head -1)
    if [ -n "$CHROME_BIN" ]; then
        echo "Starting Chromium headless..."
        $CHROME_BIN --headless=new \
            --remote-debugging-port=9222 \
            --no-sandbox \
            --disable-gpu \
            --disable-dev-shm-usage \
            > /tmp/chrome.log 2>&1 &
        sleep 2
    fi
fi

# Start opencli daemon
if command -v opencli &> /dev/null; then
    echo "Starting opencli daemon..."
    opencli daemon start || true
fi

echo "Agent Runtime ready!"
echo ""
echo "To start the Web Chat server:"
echo "  cd ~/web && python3 server.py"
echo ""
echo "Web UI will be available at: http://localhost:8765"
echo ""

# Keep container running
exec /bin/bash
