#!/bin/bash
# Quick Agent Creation Script
# Usage: ./create-agent.sh <agent-name>

set -e

AGENT_NAME=$1

if [ -z "$AGENT_NAME" ]; then
    echo "❌ Error: Agent name is required"
    echo "Usage: ./create-agent.sh <agent-name>"
    echo ""
    echo "Example:"
    echo "  ./create-agent.sh my-data-agent"
    exit 1
fi

# Validate agent name (lowercase, numbers, hyphens only)
if [[ ! "$AGENT_NAME" =~ ^[a-z0-9-]+$ ]]; then
    echo "❌ Error: Agent name must contain only lowercase letters, numbers, and hyphens"
    exit 1
fi

echo "🚀 Creating new agent: $AGENT_NAME"
echo "=================================="
echo ""

# Create directory structure
echo "📁 Creating directories..."
mkdir -p "code/$AGENT_NAME/script"
mkdir -p "code/$AGENT_NAME/tool"
mkdir -p ".openharness/agents"
mkdir -p ".openharness/skills/$AGENT_NAME"

# Create example tool JSON
echo "🔧 Creating example tool..."
cat > "code/$AGENT_NAME/tool/example_tool.json" <<EOF
{
  "name": "example_tool",
  "description": "An example tool for $AGENT_NAME",
  "command": "python3 script/example_tool.py {input}",
  "working_directory": "~/code/$AGENT_NAME",
  "input_schema": {
    "type": "object",
    "properties": {
      "input": {
        "type": "string",
        "description": "Input parameter"
      }
    },
    "required": ["input"]
  },
  "output_schema": {
    "type": "object",
    "properties": {
      "status": {
        "type": "string",
        "enum": ["success", "error"]
      },
      "result": {
        "type": "string"
      }
    }
  },
  "timeout": 60,
  "depends_on": [],
  "requires": ["python3"]
}
EOF

# Create example Python script
echo "📝 Creating example script..."
cat > "code/$AGENT_NAME/script/example_tool.py" <<'EOF'
#!/usr/bin/env python3
"""
Example tool script
"""

import sys
import json
from datetime import datetime, timezone

def main():
    if len(sys.argv) < 2:
        result = {
            "status": "error",
            "result": "Input parameter is required"
        }
        print(json.dumps(result, indent=2))
        sys.exit(1)

    input_data = sys.argv[1]

    # Your tool logic here
    result = {
        "status": "success",
        "result": f"Processed: {input_data}",
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    }

    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
EOF

chmod +x "code/$AGENT_NAME/script/example_tool.py"

# Create agent documentation
echo "📄 Creating agent documentation..."
cat > ".openharness/agents/$AGENT_NAME.md" <<EOF
# $AGENT_NAME

Agent description goes here.

## Purpose

Describe the purpose of this agent.

## Available Tools

- \`example_tool\`: Description of what the tool does

## Usage

\`\`\`
Use example_tool with input "test data"
\`\`\`

## Configuration

- Working directory: \`~/code/$AGENT_NAME\`
- Tools directory: \`~/code/$AGENT_NAME/tool\`
- Scripts directory: \`~/code/$AGENT_NAME/script\`
EOF

# Create skill documentation
echo "📚 Creating skill documentation..."
cat > ".openharness/skills/$AGENT_NAME/example_skill.md" <<EOF
# Example Skill

A sample skill for $AGENT_NAME.

## Skill Description

This skill demonstrates how to use the example_tool.

## Steps

1. Receive input from user
2. Process input using example_tool
3. Return formatted result

## Example

Input: "sample data"
Output: "Processed: sample data" with timestamp
EOF

echo ""
echo "✅ Agent '$AGENT_NAME' created successfully!"
echo ""
echo "📂 Directory structure:"
echo "   code/$AGENT_NAME/"
echo "   ├── script/"
echo "   │   └── example_tool.py"
echo "   └── tool/"
echo "       └── example_tool.json"
echo ""
echo "   .openharness/"
echo "   ├── agents/"
echo "   │   └── $AGENT_NAME.md"
echo "   └── skills/$AGENT_NAME/"
echo "       └── example_skill.md"
echo ""
echo "🎯 Next steps:"
echo "   1. Edit code/$AGENT_NAME/script/example_tool.py (implement your logic)"
echo "   2. Edit code/$AGENT_NAME/tool/example_tool.json (update tool definition)"
echo "   3. Edit .openharness/agents/$AGENT_NAME.md (document your agent)"
echo "   4. Test your tool: python3 code/$AGENT_NAME/script/example_tool.py \"test\""
echo ""
