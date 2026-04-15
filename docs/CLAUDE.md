# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AgentDevFramework is a **reusable AI agent development toolkit** extracted from a production sentiment analysis system. It provides a complete runtime environment for building custom AI agents with minimal setup.

**Key Features:**
- 🚀 One-command agent creation via `create-agent.sh`
- 🌐 WebSocket-based web UI with streaming support
- 🔧 JSON Schema-driven tool system
- 🐳 Docker Compose orchestration (3 services)
- 📦 Multi-model support via LiteLLM

**Core Architecture Pattern:**
```
Browser (WebSocket) → server.py (Starlette) → OpenHarness (stdin/stdout) → LiteLLM Proxy → LLM Providers
```

**Project Structure:**
```
AgentDevFramework/
├── code/                    # Agent implementations (one folder per agent)
│   └── {agent-name}/
│       ├── script/         # Python tool scripts
│       └── tool/           # JSON tool definitions
├── .openharness/           # OpenHarness configuration
│   ├── agents/            # Agent documentation (.md files)
│   └── skills/            # Skill definitions (per-agent folders)
├── web/                    # Web UI components
│   ├── server.py          # WebSocket gateway (Starlette ASGI)
│   └── index.html         # Frontend with streaming support
├── docs/                   # Documentation
├── docker-compose.yaml     # 3-service orchestration
├── Dockerfile             # Multi-stage runtime image
├── create-agent.sh        # ⭐ Quick agent scaffolding script
└── start.sh              # Quick start helper
```

## Quick Reference

### Essential Commands
```bash
# Create new agent
./create-agent.sh my-agent

# Start all services
./start.sh

# Enter container
docker exec -it agent-runtime bash

# Start Web UI server (inside container)
cd ~/web && python3 server.py

# Test a tool locally
python3 code/my-agent/script/tool.py "input"

# View logs
docker compose logs -f agent

# Restart after .env changes
docker compose restart agent
```

### File Locations
- **Agent code**: `code/{agent-name}/`
- **Tool definitions**: `code/{agent-name}/tool/*.json`
- **Tool scripts**: `code/{agent-name}/script/*.py`
- **Agent docs**: `.openharness/agents/{agent-name}.md`
- **Skills**: `.openharness/skills/{agent-name}/`
- **Web UI**: `web/server.py` and `web/index.html`
- **Docker config**: `docker-compose.yaml`, `Dockerfile`
- **LLM config**: `litellm-config.yaml`
- **Environment**: `.env` (gitignored)

### Important URLs
- Web UI: http://localhost:8765
- LiteLLM API: http://localhost:4000
- LiteLLM Health: http://localhost:4000/health

## Key Architecture Components

### Three-Service Docker Architecture

The system runs three interconnected containers:

1. **agent** (`agent-runtime`): Main runtime container
   - Runs `web/server.py` - WebSocket gateway using Starlette ASGI
   - Manages OpenHarness subprocess with `--backend-only` mode
   - Mounts `./code`, `./.openharness`, and `./web` directories
   - Port 8765 exposed for Web UI

2. **litellm** (`litellm-proxy`): LLM routing proxy
   - Provides OpenAI-compatible API at port 4000
   - Routes requests to multiple LLM providers (Claude, GPT-4, local models)
   - Configured via `litellm-config.yaml`
   - Environment variables from `.env`

3. **db** (`agent-postgres-db`): PostgreSQL database
   - Stores LiteLLM request logs and configuration
   - Port 5432 (internal only)
   - Data persisted in `db-data` named volume

All services communicate over `agent-network` bridge network.

### WebSocket Communication Protocol

**OHJSON Protocol** (`web/server.py`):
- OpenHarness outputs JSON events prefixed with `OHJSON:`
- Example: `OHJSON:{"type":"assistant_delta","message":"text"}`
- Non-prefixed lines are treated as log messages
- Server uses three concurrent async tasks:
  - `stdout_reader()`: OpenHarness stdout → WebSocket
  - `stderr_reader()`: OpenHarness stderr → logs
  - `ws_reader()`: WebSocket → OpenHarness stdin

**Critical**: The server spawns OpenHarness as a subprocess with pipes, not as a separate service.

### Tool System

Tools are defined in `code/{agent-name}/tool/*.json` using JSON Schema:

**Required Fields:**
- `name`: Tool identifier (snake_case)
- `description`: Human-readable purpose
- `command`: Command template with `{param}` placeholders (e.g., `python3 script/tool.py {input}`)
- `working_directory`: Execution path (e.g., `~/code/agent-1`)
- `input_schema`: JSON Schema for input validation
- `output_schema`: JSON Schema for output validation
- `timeout`: Execution timeout in seconds

**Optional Fields:**
- `depends_on`: Array of tool names (creates DAG execution order)
- `requires`: Array of required binaries/packages (for pre-checks)

**Tool Execution Flow:**
1. OpenHarness validates input against `input_schema`
2. Interpolates parameters into `command` template
3. Changes to `working_directory`
4. Executes script with timeout
5. Validates output against `output_schema`

**Tool scripts must output JSON to stdout:**
```python
#!/usr/bin/env python3
import json
import sys

result = {
    "status": "success",
    "result": "Processed data"
}
print(json.dumps(result, indent=2))
```

**Python scripts are preferred over bash** for better cross-platform support and JSON handling.

## Development Commands

### Quick Agent Creation

```bash
# Create a new agent (scaffolds complete structure)
./create-agent.sh my-data-agent

# Generated structure:
# code/my-data-agent/
#   ├── script/example_tool.py
#   └── tool/example_tool.json
# .openharness/
#   ├── agents/my-data-agent.md
#   └── skills/my-data-agent/example_skill.md

# Test the generated tool
python3 code/my-data-agent/script/example_tool.py "test input"
```

### Starting the Environment

```bash
# Quick start (checks .env, starts all services)
./start.sh

# Manual start
cp .env.example .env  # First time only
docker compose up -d
docker compose logs -f

# Enter agent container
docker exec -it agent-runtime bash

# Start WebSocket server (inside container)
cd ~/web && python3 server.py

# Access Web UI
# http://localhost:8765
```

### Container Management

```bash
# View service status
docker compose ps

# View logs (specific service)
docker compose logs -f agent
docker compose logs -f litellm

# Restart services
docker compose restart agent

# Rebuild after Dockerfile changes
docker compose build --no-cache

# Stop all services
docker compose down

# Clean up volumes (WARNING: deletes database)
docker compose down -v
```

### Testing and Debugging

```bash
# Test LiteLLM health
curl http://localhost:4000/health

# Test WebSocket server
curl http://localhost:8765/

# Check PostgreSQL
docker exec agent-postgres-db pg_isready -U admin

# Manual tool script testing
python3 code/agent-1/script/hello_world.py "test input"

# Inside container
docker exec -it agent-runtime bash
python3 ~/code/agent-1/script/hello_world.py "test"

# Check OpenHarness version
docker exec agent-runtime python3 -m openharness --version

# List all available tools
docker exec agent-runtime find /home/ubuntu/code -name "*.json" -path "*/tool/*"
```

## Creating New Tools

### Automated Method (Recommended)

```bash
# Use create-agent.sh to scaffold a complete agent
./create-agent.sh my-new-agent

# This creates:
# - code/my-new-agent/script/example_tool.py (Python implementation)
# - code/my-new-agent/tool/example_tool.json (JSON definition)
# - .openharness/agents/my-new-agent.md (documentation)
# - .openharness/skills/my-new-agent/ (skill definitions)

# Then customize the generated files
```

### Manual Method

**Step 1: Define Tool JSON**

Create `code/my-agent/tool/my_tool.json`:
```json
{
  "name": "my_tool",
  "description": "Description of what the tool does",
  "command": "python3 script/my_tool.py {input}",
  "working_directory": "~/code/my-agent",
  "input_schema": {
    "type": "object",
    "properties": {
      "input": {
        "type": "string",
        "description": "Input parameter description"
      }
    },
    "required": ["input"]
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

**Step 2: Implement Script**

Create `code/my-agent/script/my_tool.py`:
```python
#!/usr/bin/env python3
import sys
import json
from datetime import datetime

def main():
    if len(sys.argv) < 2:
        result = {"status": "error", "result": "Input is required"}
        print(json.dumps(result, indent=2))
        sys.exit(1)

    input_data = sys.argv[1]

    # Business logic here
    result = {
        "status": "success",
        "result": f"Processed: {input_data}",
        "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    }

    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
```

Make executable:
```bash
chmod +x code/my-agent/script/my_tool.py
```

**Step 3: Test**

Local test:
```bash
python3 code/my-agent/script/my_tool.py "test data"
```

Web UI test (no restart needed - OpenHarness auto-discovers):
```
Use my_tool with input "test data"
```

## Configuration Files

### Environment Variables (.env)

Required for AWS Bedrock (Claude models):
```bash
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

LiteLLM authentication:
```bash
LITELLM_MASTER_KEY=sk-your-secret
```

Database credentials:
```bash
POSTGRES_USER=admin
POSTGRES_PASSWORD=...
POSTGRES_DB=litellm
DATABASE_URL=postgresql://admin:password@db:5432/litellm
```

### LiteLLM Model Configuration (litellm_config.yaml)

Add models to `model_list`:
```yaml
model_list:
  - model_name: claude-sonnet
    litellm_params:
      model: us.anthropic.claude-sonnet-4-6
      aws_access_key_id: os.environ/AWS_ACCESS_KEY_ID
      aws_secret_access_key: os.environ/AWS_SECRET_ACCESS_KEY
      aws_region_name: us-west-2
```

**Important**: Use `os.environ/VAR_NAME` syntax to reference .env variables.

### OpenHarness Settings (.openharness/settings.json)

Default OpenHarness configuration (auto-created if missing):
```json
{
  "model": "claude-sonnet",
  "permission_mode": "full_auto",
  "max_turns": 200,
  "memory_enabled": true
}
```

**Agent Documentation** (`.openharness/agents/{agent-name}.md`):
- Markdown files describing agent purpose and capabilities
- Referenced by OpenHarness for context
- Created automatically by `create-agent.sh`

**Skill Definitions** (`.openharness/skills/{agent-name}/`):
- Per-agent skill documentation
- Step-by-step task descriptions
- Examples of tool usage patterns

## Multi-Stage Dockerfile

The Dockerfile uses a three-stage build to minimize final image size:

**Stage 1 (downloader)**: Downloads CLI binaries
- bat, fzf, ripgrep, fd, eza, sd, codex, starship
- opencli browser bridge extension

**Stage 2 (python-builder)**: Builds Python virtualenv
- Creates venv in `/opt/venv`
- Installs `openharness-ai` and `graphifyy`

**Stage 3 (final)**: Assembles runtime image
- Copies binaries from stage 1
- Copies venv from stage 2
- Installs Node.js 22.14.0 via nvm
- Installs Chromium for OpenCLI
- Sets up ubuntu user (uid=1000)

**If modifying Dockerfile**: 
- Ensure base image in stage 2 matches stage 3 to avoid Python binary path mismatches
- Current base: `ubuntu:24.04`
- Python version: 3.12
- Node.js version: 22.14.0 (managed by nvm)
- User: `ubuntu` (uid=1000) for compatibility with host file permissions

## Complete Workflow Example

### Creating a Data Processing Agent

**Step 1: Scaffold the agent**
```bash
./create-agent.sh data-processor
```

**Step 2: Define additional tools**

Create `code/data-processor/tool/fetch_data.json`:
```json
{
  "name": "fetch_data",
  "description": "Fetch data from API endpoint",
  "command": "python3 script/fetch_data.py {url}",
  "working_directory": "~/code/data-processor",
  "input_schema": {
    "type": "object",
    "properties": {
      "url": {"type": "string", "format": "uri"}
    },
    "required": ["url"]
  },
  "output_schema": {
    "type": "object",
    "properties": {
      "status": {"type": "string"},
      "data": {"type": "array"}
    }
  },
  "timeout": 30
}
```

**Step 3: Implement the script**

Create `code/data-processor/script/fetch_data.py`:
```python
#!/usr/bin/env python3
import sys
import json
import urllib.request

def main():
    url = sys.argv[1]
    
    try:
        with urllib.request.urlopen(url, timeout=10) as response:
            data = json.loads(response.read().decode())
            
        result = {
            "status": "success",
            "data": data if isinstance(data, list) else [data]
        }
    except Exception as e:
        result = {
            "status": "error",
            "message": str(e)
        }
        sys.exit(1)
    
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
```

**Step 4: Test locally**
```bash
chmod +x code/data-processor/script/fetch_data.py
python3 code/data-processor/script/fetch_data.py "https://api.example.com/data"
```

**Step 5: Test in Web UI**
```
Use fetch_data with url "https://jsonplaceholder.typicode.com/posts/1"
```

**Step 6: Document the agent**

Edit `.openharness/agents/data-processor.md`:
```markdown
# Data Processor Agent

Fetches and processes data from external APIs.

## Available Tools

- `fetch_data`: Retrieves JSON data from HTTP endpoints
- `example_tool`: Processes and transforms data

## Workflow

1. Fetch data from API using `fetch_data`
2. Process with `example_tool`
3. Return formatted results
```

## Best Practices

### Tool Design

✅ **DO:**
- Keep tools focused on a single responsibility
- Use descriptive names (verb_noun pattern: `fetch_data`, `process_text`)
- Validate all inputs thoroughly
- Return structured JSON output
- Include timestamps in results
- Use proper error handling with exit codes
- Document parameters in input_schema descriptions

❌ **DON'T:**
- Mix multiple concerns in one tool
- Return plain text instead of JSON
- Use hardcoded paths or credentials
- Ignore timeouts (set realistic limits)
- Skip input validation

### Agent Organization

✅ **DO:**
- One agent per logical domain (e.g., `data-collector`, `report-generator`)
- Group related tools within the same agent
- Document agent purpose in `.openharness/agents/{name}.md`
- Use dependency chains (`depends_on`) for workflows

❌ **DON'T:**
- Create monolithic agents with unrelated tools
- Duplicate tools across multiple agents (create shared utilities instead)

### Security

✅ **DO:**
- Store API keys in `.env` (never commit to git)
- Validate and sanitize all user inputs
- Use timeouts to prevent hanging processes
- Limit file system access via `working_directory`

❌ **DON'T:**
- Hardcode credentials in scripts
- Execute unsanitized shell commands
- Allow unlimited execution time
- Grant broad file system access

### Testing

✅ **DO:**
- Test tools locally before deploying
- Verify JSON output format matches schema
- Test error cases (missing params, network failures)
- Check timeout behavior

❌ **DON'T:**
- Deploy untested tools to production
- Assume network resources are always available

## Tool Dependency DAG

Tools can declare dependencies using `depends_on` field. OpenHarness automatically:
1. Builds dependency graph
2. Detects cycles (fails if found)
3. Executes tools in topological order
4. Runs independent tools in parallel

Example dependency chain:
```json
// collect.json
{"name": "collect", "depends_on": []}

// process.json
{"name": "process", "depends_on": ["collect"]}

// analyze.json
{"name": "analyze", "depends_on": ["process"]}
```

Execution order: `collect → process → analyze`

## Web UI Event Types

The `web/index.html` WebSocket client handles these event types:

- `ready`: Backend initialized, sends available commands
- `state_snapshot`: Current model/provider/cwd state
- `transcript_item`: Chat message (user/assistant/system/log)
- `assistant_delta`: Streaming text chunk (batched for performance)
- `assistant_complete`: Response finished
- `tool_started`: Tool execution begins (shows tool card)
- `tool_completed`: Tool execution ends (updates tool card)
- `permission_request`: Modal dialog for permission
- `question_request`: Modal dialog for user input
- `error`: Error message display
- `shutdown`: Session terminated

**Streaming optimization**: Text deltas are batched (max 256 chars or 33ms) before DOM updates to prevent performance issues.

## Common Pitfalls

**Server.py not running**: The WebSocket server must be manually started inside the container. It's not auto-started by entrypoint.sh. Run `cd ~/web && python3 server.py` inside the agent container.

**Tool output not JSON**: Tools must output valid JSON to stdout. Use `json.dumps()` in Python or `cat <<EOF` in bash to avoid escaping issues.

**Environment variables not loaded**: Changes to `.env` require container restart (`docker compose restart agent`).

**OpenHarness can't find tools**: 
- Tool JSON files must be in `code/{agent-name}/tool/*.json`
- Verify `working_directory` in JSON matches the agent folder: `~/code/{agent-name}`
- Use `find /home/ubuntu/code -name "*.json"` inside container to debug

**LiteLLM 401 errors**: Check `LITELLM_MASTER_KEY` matches between `.env` and `docker-compose.yaml` environment.

**Port conflicts**: Default ports are 4000 (LiteLLM) and 8765 (Web UI). Change in `docker-compose.yaml` if needed.

**Tool scripts not executable**: Run `chmod +x code/{agent}/script/*.py` after creating new scripts.

**Python path issues**: Tool `command` should use relative paths (e.g., `python3 script/tool.py`) since `working_directory` is set in the JSON.

## File Modification Impact

| File Modified | Action Required |
|---------------|-----------------|
| `web/server.py` or `web/index.html` | Restart server.py process inside container (Ctrl+C then rerun) |
| `docker-compose.yaml` | `docker compose up -d` (applies changes) |
| `Dockerfile` | `docker compose build --no-cache` then `up -d` |
| `.env` | `docker compose restart agent` |
| `litellm-config.yaml` | `docker compose restart litellm` |
| `code/**/tool/*.json` | No restart needed (OpenHarness auto-discovers) |
| `code/**/script/*.py` | No restart needed (executed on demand) |
| `.openharness/agents/*.md` | No restart needed (loaded by OpenHarness at runtime) |
| `.openharness/skills/**/*.md` | No restart needed (loaded by OpenHarness at runtime) |

## Volume Mounts

- `./code` → `/home/ubuntu/code` (read-write, agent implementations)
- `./.openharness` → `/home/ubuntu/.openharness` (read-write, configuration and docs)
- `./web` → `/home/ubuntu/web` (read-write, WebSocket server and UI)
- `db-data` → `/var/lib/postgresql/data` (named volume, database persistence)

Changes to mounted directories are immediately visible inside containers without restart.

## Agent Naming Convention

- Agent names: lowercase letters, numbers, hyphens only (e.g., `my-data-agent`)
- Tool names: snake_case (e.g., `collect_data`)
- Directory structure enforced by `create-agent.sh` validation
- Each agent is isolated in its own `code/{agent-name}/` folder

## Language Support

- **Python (recommended)**: Better JSON handling, cross-platform compatibility
- **Bash**: Suitable for simple shell operations, pipe commands
- **Node.js**: Available (Node 22.14.0 via nvm)
- Tools can call any binary available in the container
