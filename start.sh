#!/bin/bash
# Quick start script for AgentDevFramework

set -e

echo "🚀 AgentDevFramework - Quick Start"
echo "===================================="
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Creating from .env.example..."
    cp .env.example .env
    echo "✅ Created .env file"
    echo "⚠️  Please edit .env and add your API keys!"
    echo ""
    read -p "Press Enter to continue after editing .env..."
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "🐳 Starting Docker services..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check PostgreSQL
echo "   Checking PostgreSQL..."
docker exec agent-postgres-db pg_isready -U admin > /dev/null 2>&1 && echo "   ✅ PostgreSQL ready" || echo "   ⚠️  PostgreSQL not ready yet"

# Check LiteLLM
echo "   Checking LiteLLM..."
curl -s http://localhost:4000/health > /dev/null 2>&1 && echo "   ✅ LiteLLM ready" || echo "   ⚠️  LiteLLM not ready yet (may take a few more seconds)"

echo ""
echo "✅ Services started successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Enter the agent container:"
echo "      docker exec -it agent-runtime bash"
echo ""
echo "   2. Start the Web Chat server (inside container):"
echo "      cd ~/web && python3 server.py"
echo ""
echo "   3. Open your browser to:"
echo "      http://localhost:8765"
echo ""
echo "🔍 Useful commands:"
echo "   - View logs: docker compose logs -f"
echo "   - Stop services: docker compose down"
echo "   - Rebuild: docker compose build --no-cache"
echo ""
