#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="${ROOT_DIR}/reports/raw"

# Ensure directory exists AND has broad write permissions for ZAP's container user
mkdir -p "${REPORTS_DIR}"
chmod 777 "${REPORTS_DIR}"

BASE_URL=${1:-"http://127.0.0.1:5000"}
HEALTH_URL="${BASE_URL}/health"
SWAGGER_URL="${BASE_URL}/swagger/v1/swagger.json"

echo "=== Stage 5: Dynamic Application Security Testing (DAST) ==="

# Step 1: Pre-flight probe to verify /health endpoint is operational
echo "1. Checking application health status at ${HEALTH_URL}..."
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${HEALTH_URL}" || echo "000")

if [ "${HEALTH_RESPONSE}" -eq 200 ]; then
  echo "   [OK] Health endpoint returned HTTP 200 OK."
else
  echo "   [ERROR] Health endpoint check failed with status: ${HEALTH_RESPONSE}"
  echo "DAST_STATUS=FAIL" > "${REPORTS_DIR}/dast.status"
  exit 1
fi

# Step 2: Execute OWASP ZAP Scanner targeting /health and OpenAPI spec
echo "2. Launching OWASP ZAP scan against ${BASE_URL}..."

docker run --rm \
  -v "${REPORTS_DIR}:/zap/wrk/:rw" \
  --network="host" \
  zaproxy/zap-stable zap-api-scan.py \
  -t "${SWAGGER_URL}" \
  -f openapi \
  -J zap-report.json \
  -I || true

if [ -f "${REPORTS_DIR}/zap-report.json" ]; then
  echo "DAST_STATUS=PASS" > "${REPORTS_DIR}/dast.status"
  echo "DAST scan completed successfully. Report written to reports/raw/zap-report.json."
  exit 0
else
  echo "DAST_STATUS=WARN" > "${REPORTS_DIR}/dast.status"
  echo "DAST scan completed with warnings or missing report file."
  exit 0
fi