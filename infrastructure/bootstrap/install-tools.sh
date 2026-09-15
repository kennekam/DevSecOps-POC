#!/usr/bin/env bash
set -euo pipefail

echo "Verifying installed runtime tools..."

REQUIRED_BINARIES=("docker" "git" "nginx" "jq" "dotnet")

for bin in "${REQUIRED_BINARIES[@]}"; do
  if ! command -v "$bin" &> /dev/null; then
    echo "ERROR: Required binary '$bin' is not installed." >&2
    exit 1
  else
    echo "  [OK] Found $bin: $(command -v "$bin")"
  fi
done

# Ensure Docker Compose V2 plugin is available
if ! docker compose version &> /dev/null; then
  echo "ERROR: 'docker compose' plugin is missing." >&2
  exit 1
else
  echo "  [OK] Found Docker Compose plugin: $(docker compose version)"
fi