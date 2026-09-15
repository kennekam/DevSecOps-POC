#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="${ROOT_DIR}/reports/raw"

DOJO_URL=${DOJO_URL:-"http://127.0.0.1:8080"}
DOJO_API_KEY=${DOJO_API_KEY:-""}

if [ -z "${DOJO_API_KEY}" ]; then
  echo "WARN: DOJO_API_KEY not supplied. Skipping DefectDojo automatic ingestion."
  exit 0
fi

echo "Importing Scan Results into DefectDojo..."

upload_scan() {
  local scan_type="$1"
  local file_path="$2"

  if [ -f "${file_path}" ]; then
    echo "  -> Ingesting ${scan_type}..."
    curl -X POST "${DOJO_URL}/api/v2/import-scan/" \
      -H "Authorization: Token ${DOJO_API_KEY}" \
      -F "active=true" \
      -F "verified=true" \
      -F "scan_type=${scan_type}" \
      -F "minimum_severity=Info" \
      -F "engagement_name=Security POC Pipeline" \
      -F "product_name=RcsApi" \
      -F "file=@${file_path}" >/dev/null 2>&1 || echo "    Failed to upload ${scan_type}"
  fi
}

upload_scan "Gitleaks Scan" "${REPORTS_DIR}/gitleaks-report.json"
upload_scan "Semgrep JSON Report" "${REPORTS_DIR}/semgrep-report.json"
upload_scan "Trivy Scan" "${REPORTS_DIR}/trivy-report.json"
upload_scan "ZAP Scan" "${REPORTS_DIR}/zap-report.json"

echo "DefectDojo Ingestion Phase Complete."