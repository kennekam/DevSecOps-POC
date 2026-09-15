#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_SOURCE="${SCRIPT_DIR}/../nginx/security-poc.conf"
CONF_TARGET="/etc/nginx/sites-available/security-poc.conf"
ENABLED_TARGET="/etc/nginx/sites-enabled/security-poc.conf"

echo "Deploying Nginx Reverse Proxy Configuration..."

if [ ! -f "${CONF_SOURCE}" ]; then
  echo "ERROR: Source Nginx configuration missing at ${CONF_SOURCE}" >&2
  exit 1
fi

cp "${CONF_SOURCE}" "${CONF_TARGET}"

# Disable default site if it exists
if [ -f "/etc/nginx/sites-enabled/default" ]; then
  rm -f "/etc/nginx/sites-enabled/default"
fi

ln -sf "${CONF_TARGET}" "${ENABLED_TARGET}"

echo "Testing Nginx configuration syntax..."
nginx -t

echo "Reloading Nginx service..."
systemctl reload nginx