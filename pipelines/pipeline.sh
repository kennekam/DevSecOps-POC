#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Track stage statuses
SECRETS_RES="${YELLOW}SKIP${NC}"
SAST_RES="${YELLOW}SKIP${NC}"
SCA_RES="${YELLOW}SKIP${NC}"
DEPLOY_RES="${YELLOW}SKIP${NC}"
DAST_RES="${YELLOW}SKIP${NC}"

GLOBAL_EXIT=0

print_header() {
  echo -e "\n${BLUE}=================================================${NC}"
  echo -e "${BLUE}        DEVSECOPS SECURITY PIPELINE              ${NC}"
  echo -e "${BLUE}=================================================${NC}\n"
}

print_summary() {
  echo -e "\n${BLUE}=================================================${NC}"
  echo -e "${BLUE}            SECURITY GATE SUMMARY                ${NC}"
  echo -e "${BLUE}=================================================${NC}"
  echo -e " [1/5] Secrets Scan    : ${SECRETS_RES}"
  echo -e " [2/5] SAST Scan       : ${SAST_RES}"
  echo -e " [3/5] SCA Scan        : ${SCA_RES}"
  echo -e " [4/5] Deploy Target   : ${DEPLOY_RES}"
  echo -e " [5/5] DAST Scan       : ${DAST_RES}"
  echo -e "${BLUE}=================================================${NC}"

  if [ ${GLOBAL_EXIT} -eq 0 ]; then
    echo -e "${GREEN} PIPELINE COMPLETE: ALL QUALITY GATES PASSED ${NC}\n"
  else
    echo -e "${RED} PIPELINE FAILED: QUALITY GATE VIOLATIONS DETECTED ${NC}\n"
  fi
}

print_header

# --- STAGE 1: Secrets Scanning ---
echo -e "${BLUE}[1/5] Executing Secrets Scan...${NC}"
if "${SCRIPT_DIR}/secrets.sh"; then
  SECRETS_RES="${GREEN}PASS${NC}"
else
  SECRETS_RES="${RED}FAIL${NC}"
  GLOBAL_EXIT=1
fi

# --- STAGE 2: SAST Scanning ---
echo -e "\n${BLUE}[2/5] Executing SAST Scan...${NC}"
if "${SCRIPT_DIR}/sast.sh"; then
  SAST_RES="${GREEN}PASS${NC}"
else
  SAST_RES="${RED}FAIL${NC}"
  GLOBAL_EXIT=1
fi

# --- STAGE 3: SCA Scanning ---
echo -e "\n${BLUE}[3/5] Executing SCA Scan...${NC}"
if "${SCRIPT_DIR}/sca.sh"; then
  SCA_RES="${GREEN}PASS${NC}"
else
  SCA_RES="${RED}FAIL${NC}"
  GLOBAL_EXIT=1
fi

# --- STAGE 4: Deployment Check / Refresh ---
echo -e "\n${BLUE}[4/5] Deploying Application Target...${NC}"
if cd "${ROOT_DIR}/infrastructure/docker" && docker compose up -d --build rcs-api; then
  DEPLOY_RES="${GREEN}PASS${NC}"
else
  DEPLOY_RES="${RED}FAIL${NC}"
  GLOBAL_EXIT=1
fi

# --- STAGE 5: DAST Scanning ---
echo -e "\n${BLUE}[5/5] Executing Dynamic Analysis (DAST)...${NC}"
if "${SCRIPT_DIR}/dast.sh" "http://127.0.0.1:5000"; then
  DAST_RES="${GREEN}PASS${NC}"
else
  DAST_RES="${YELLOW}WARN${NC}"
fi

# --- POST-PROCESSING: Evidence Collection & Ingestion ---
echo -e "\n${BLUE}[POST] Generating Evidence Bundle...${NC}"
"${SCRIPT_DIR}/evidence.sh" || true

echo -e "\n${BLUE}[POST] Syncing with DefectDojo...${NC}"
"${SCRIPT_DIR}/dojo-import.sh" || true

# Output Final Governance Summary Block
print_summary

exit ${GLOBAL_EXIT}