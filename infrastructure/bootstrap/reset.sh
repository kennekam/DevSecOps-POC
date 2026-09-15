#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}=================================================${NC}"
echo -e "${RED}        FULL ENVIRONMENT RESET & BOOTSTRAP       ${NC}"
echo -e "${RED}=================================================${NC}"

read -p "This will wipe all generated reports, evidence, and container state. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Reset aborted."
  exit 0
fi

echo -e "\n${BLUE}[1/4] Stopping and Removing Containers & Volumes...${NC}"
cd "${ROOT_DIR}/infrastructure/docker"
docker compose down -v --remove-orphans || true

echo -e "\n${BLUE}[2/4] Purging Reports and Evidence Archives...${NC}"
rm -rf "${ROOT_DIR}/reports/raw/"*
rm -rf "${ROOT_DIR}/evidence/"*
mkdir -p "${ROOT_DIR}/reports/raw" "${ROOT_DIR}/evidence"

echo -e "\n${BLUE}[3/4] Cleaning Docker Cache...${NC}"
docker image prune -f

echo -e "\n${BLUE}[4/4] Triggering Full Bootstrap...${NC}"
"${SCRIPT_DIR}/bootstrap.sh"

echo -e "\n${GREEN}Environment successfully reset to pristine baseline.${NC}"