#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="${ROOT_DIR}/reports/raw"
EVIDENCE_DIR="${ROOT_DIR}/evidence"

mkdir -p "${EVIDENCE_DIR}"

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "uncommitted")
ARCHIVE_NAME="evidence-${TIMESTAMP}-${COMMIT_HASH}.tar.gz"

echo "Generating Immutable Evidence Package..."

# Create manifest file
cat << EOF > "${REPORTS_DIR}/manifest.json"
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "commit_hash": "${COMMIT_HASH}",
  "branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")",
  "executed_by": "$(whoami)",
  "reports": [
    "gitleaks-report.json",
    "semgrep-report.json",
    "trivy-report.json",
    "zap-report.json"
  ]
}
EOF

tar -czf "${EVIDENCE_DIR}/${ARCHIVE_NAME}" -C "${ROOT_DIR}/reports" raw

echo "Evidence bundle created at: ${EVIDENCE_DIR}/${ARCHIVE_NAME}"