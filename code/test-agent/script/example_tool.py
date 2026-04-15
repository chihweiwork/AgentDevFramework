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
