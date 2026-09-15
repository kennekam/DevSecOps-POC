#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}        FAST ITERATION: REBUILD & RERUN          ${NC}"
echo -e "${BLUE}=================================================${NC}"

echo -e "\n${BLUE}[1/3] Clearing Previous Raw Reports...${NC}"
rm -rf "${ROOT_DIR}/reports/raw/*"
mkdir -p "${ROOT_DIR}/reports/raw"

echo -e "\n${BLUE}[2/3] Rebuilding Target Application...${NC}"
cd "${ROOT_DIR}/infrastructure/docker"
docker compose build rcs-api
docker compose up -d rcs-api

echo -e "\n${BLUE}[3/3] Triggering Security Pipeline...${NC}"
"${ROOT_DIR}/pipelines/pipeline.sh"

echo -e "\n${GREEN}Fast execution run complete.${NC}"