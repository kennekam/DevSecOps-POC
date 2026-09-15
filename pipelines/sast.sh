#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="${ROOT_DIR}/reports/raw"
mkdir -p "${REPORTS_DIR}"

echo "Executing Semgrep SAST Scan..."

docker run --rm \
  -v "${ROOT_DIR}:/src" \
  returntocorp/semgrep semgrep scan \
  --config=auto \
  --json -o /src/reports/raw/semgrep-report.json /src || true

HIGH_CRIT_COUNT=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' "${REPORTS_DIR}/semgrep-report.json" 2>/dev/null || echo 0)

if [ "${HIGH_CRIT_COUNT}" -gt 0 ]; then
  echo "SAST_STATUS=FAIL" > "${REPORTS_DIR}/sast.status"
  echo "SAST scan failed with ${HIGH_CRIT_COUNT} High/Critical errors."
  exit 1
else
  echo "SAST_STATUS=PASS" > "${REPORTS_DIR}/sast.status"
  echo "SAST scan passed."
  exit 0
fi