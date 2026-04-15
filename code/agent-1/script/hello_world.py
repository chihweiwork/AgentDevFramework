#!/usr/bin/env python3
"""
Example tool script: hello_world
Description: Echoes a message back to the user
"""

import sys
import json
from datetime import datetime, timezone

def main():
    # Get message from command line argument
    message = sys.argv[1] if len(sys.argv) > 1 else "Hello, World!"

    # Get current timestamp
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Output JSON result
    result = {
        "status": "success",
        "result": f"Echo: {message}",
        "timestamp": timestamp
    }

    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
