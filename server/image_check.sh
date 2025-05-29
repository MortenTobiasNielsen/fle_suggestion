#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-factorio_0.2.0}"

# Check Docker daemon
if ! command -v docker &>/dev/null; then
  echo "Docker not installed." >&2; exit 1
fi
if ! docker info &>/dev/null; then
  echo "Docker daemon unreachable." >&2; exit 1
fi

# Ensure image exists
if ! docker image inspect "$IMAGE" &>/dev/null; then
  echo "Building image $IMAGE..."
  docker build -t "$IMAGE" "$(dirname "$0")"
fi
