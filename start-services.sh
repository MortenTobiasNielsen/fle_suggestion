#!/bin/bash

# Default values
SCENARIO_NAME=${SCENARIO_NAME:-"FLE_Lab"}
FACTORIO_PORT=${FACTORIO_PORT:-34197}
RCON_PORT=${RCON_PORT:-27015}
RCON_PASSWORD=${RCON_PASSWORD:-factorio}
API_PORT=${API_PORT:-5000}

# Build Factorio command
FACTORIO_CMD="/opt/factorio/bin/x64/factorio"

if [ -n "$SCENARIO_NAME" ]; then
    FACTORIO_CMD="$FACTORIO_CMD --start-server-load-scenario $SCENARIO_NAME"
else
    FACTORIO_CMD="$FACTORIO_CMD --start-server-load-latest"
fi

FACTORIO_CMD="$FACTORIO_CMD --server-settings /opt/factorio/config/server-settings.json --port $FACTORIO_PORT --rcon-port $RCON_PORT --rcon-password $(cat /opt/factorio/config/rconpw) --mod-directory /opt/factorio/mods"

# Start Factorio server in background
echo "Starting Factorio server with scenario: ${SCENARIO_NAME:-latest}"
echo "Command: $FACTORIO_CMD"
$FACTORIO_CMD &

# Wait a moment for Factorio to start
sleep 5

# Start API server
echo "Starting API server on port $API_PORT..."
cd /opt/api
exec ./API --urls "http://0.0.0.0:$API_PORT" 