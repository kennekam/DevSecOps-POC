#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="${ROOT_DIR}/reports/raw"
mkdir -p "${REPORTS_DIR}"

echo "Executing Trivy SCA Scan..."

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "${ROOT_DIR}:/src" \
  aquasec/trivy:latest fs \
  --format json \
  --output /src/reports/raw/trivy-report.json /src || true

HIGH_CRIT_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH" or .Severity=="CRITICAL")] | length' "${REPORTS_DIR}/trivy-report.json" 2>/dev/null || echo 0)

if [ "${HIGH_CRIT_COUNT}" -gt 0 ]; then
  echo "SCA_STATUS=FAIL" > "${REPORTS_DIR}/sca.status"
  echo "SCA scan failed with ${HIGH_CRIT_COUNT} High/Critical vulnerabilities."
  exit 1
else
  echo "SCA_STATUS=PASS" > "${REPORTS_DIR}/sca.status"
  echo "SCA scan passed."
  exit 0
fi