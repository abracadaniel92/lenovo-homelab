#!/bin/bash
# Script to enable authentication methods in Mattermost config.json

echo "Enabling authentication methods in Mattermost..."

# Use mattermost CLI to check if we can access the config
docker exec mattermost mattermost config show 2>&1 || {
    echo "Cannot access config via CLI, trying direct JSON modification..."
    
    # Try to modify config.json directly via Python (if available) or use jq
    docker exec mattermost sh -c '
        if command -v python3 >/dev/null 2>&1; then
            python3 << EOF
import json
import os

config_path = "/mattermost/config/config.json"
if os.path.exists(config_path):
    with open(config_path, "r") as f:
        config = json.load(f)
    
    # Enable email authentication
    config["EmailSettings"]["EnableSignUpWithEmail"] = True
    config["EmailSettings"]["EnableSignInWithEmail"] = True
    config["EmailSettings"]["EnableSignInWithUsername"] = True
    
    # Save config
    with open(config_path, "w") as f:
        json.dump(config, f, indent=4)
    print("Config updated successfully")
else:
    print(f"Config file not found at {config_path}")
EOF
        else
            echo "Python3 not available in container, config may need manual update via System Console"
        fi
    '
}

echo "Done. Please restart Mattermost: docker compose restart mattermost"

