#!/bin/zsh

# Start API Gateway Script
# This script ensures node is in PATH before starting

cd "$(dirname "$0")/.."

# Try to find node in common locations
if command -v node >/dev/null 2>&1; then
    NODE_CMD="node"
elif [ -f "/usr/local/bin/node" ]; then
    NODE_CMD="/usr/local/bin/node"
elif [ -f "/opt/homebrew/bin/node" ]; then
    NODE_CMD="/opt/homebrew/bin/node"  
elif [ -f "$HOME/.nvm/versions/node/*/bin/node" ]; then
    NODE_CMD=$(ls $HOME/.nvm/versions/node/*/bin/node | head -1)
else
    echo "Error: node not found in PATH"
    echo "Please ensure Node.js is installed"
    exit 1
fi

echo "Using node: $NODE_CMD"
echo "Starting API Gateway..."

# Change to api-gateway directory
cd api-gateway

# Start the server
$NODE_CMD dist/server.js
