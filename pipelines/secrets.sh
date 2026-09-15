#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="${ROOT_DIR}/reports/raw"
mkdir -p "${REPORTS_DIR}"

echo "Executing Gitleaks Secrets Scan..."

docker run --rm \
  -v "${ROOT_DIR}:/path" \
  zricethezav/gitleaks:latest \
  detect --source="/path" --report-path="/path/reports/raw/gitleaks-report.json" --exit-code=0 || true

FINDINGS_COUNT=$(jq '. | length' "${REPORTS_DIR}/gitleaks-report.json" 2>/dev/null || echo 0)

if [ "${FINDINGS_COUNT}" -gt 0 ]; then
  echo "SECRETS_STATUS=FAIL" > "${REPORTS_DIR}/secrets.status"
  echo "Found ${FINDINGS_COUNT} hardcoded secrets!"
  exit 1
else
  echo "SECRETS_STATUS=PASS" > "${REPORTS_DIR}/secrets.status"
  echo "No secrets detected."
  exit 0
fi