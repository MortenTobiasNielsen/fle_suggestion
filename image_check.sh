#!/usr/bin/env bash
set -euo pipefail

# Cross-platform Docker image checker and builder
# Works on Linux, macOS, and Windows (with bash environment like Git Bash or WSL)

IMAGE="${1:-factorio_0.2.0}"

# Function to redirect both stdout and stderr to null
redirect_to_null() {
    "$@" >/dev/null 2>&1
}

# Check if we're running in a proper bash environment
if [ -z "${BASH_VERSION:-}" ]; then
    echo "Error: This script requires bash. Please run with bash or use Git Bash on Windows." >&2
    exit 1
fi

# Check Docker installation
echo "Checking Docker installation..."
if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker not installed or not in PATH." >&2
    echo "Please install Docker Desktop and ensure it's in your PATH." >&2
    exit 1
fi

# Check Docker daemon
echo "Checking Docker daemon..."
if ! redirect_to_null docker info; then
    echo "Error: Docker daemon unreachable." >&2
    echo "Please ensure Docker Desktop is running." >&2
    echo "On Windows: Start Docker Desktop application" >&2
    echo "On Linux: sudo systemctl start docker" >&2
    echo "On macOS: Start Docker Desktop application" >&2
    exit 1
fi

# Get script directory in a cross-platform way
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure image exists
echo "Checking if Docker image '$IMAGE' exists..."
if ! redirect_to_null docker image inspect "$IMAGE"; then
    echo "Image '$IMAGE' not found. Building image..."
    
    # Check if Dockerfile exists
    if [ ! -f "$SCRIPT_DIR/Dockerfile" ]; then
        echo "Error: Dockerfile not found in $SCRIPT_DIR" >&2
        exit 1
    fi
    
    # Build the image for x86_64 architecture (Factorio requirement)
    echo "Building Docker image '$IMAGE' from $SCRIPT_DIR..."
    
    # Check if we're on ARM and warn the user
    if command -v uname >/dev/null 2>&1; then
        case "$(uname -m)" in
            arm64|aarch64)
                echo "⚠️  Warning: You are on ARM64 hardware, but Factorio only supports x86_64."
                echo "   This will build an x86_64 image that will run via emulation."
                echo "   Performance may be reduced compared to native x86_64 hardware."
                ;;
        esac
    fi
    
    # Always build for linux/amd64 since Factorio only supports x86_64
    PLATFORM="linux/amd64"
    echo "Building for platform: $PLATFORM (Factorio requirement)"
    if ! docker build --platform "$PLATFORM" -t "$IMAGE" "$SCRIPT_DIR"; then
        echo "Error: Failed to build Docker image '$IMAGE'" >&2
        exit 1
    fi
    
    echo "Successfully built Docker image '$IMAGE'"
else
    echo "Docker image '$IMAGE' already exists."
fi

echo "Docker image check completed successfully."
