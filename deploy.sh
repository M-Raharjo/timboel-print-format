#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: deploy_print_format.sh <print-format-name> <html-file>"
  exit 1
fi

PRINT_FORMAT_NAME="$1"
HTML_FILE="$2"

if [ ! -f "$HTML_FILE" ]; then
  echo "Missing file: $HTML_FILE"
  exit 1
fi

if [ -z "${ERPNEXT_BASE_URL:-}" ] || [ -z "${ERPNEXT_API_KEY:-}" ] || [ -z "${ERPNEXT_API_SECRET:-}" ]; then
  echo "Missing ERPNext environment variables."
  exit 1
fi

ENCODED_NAME="$(python3 - <<'PY' "$PRINT_FORMAT_NAME"
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe=""))
PY
)"

python3 - <<'PY' "$HTML_FILE" > /tmp/print-format-payload.json
import json, sys, pathlib
html = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
print(json.dumps({"html": html}, ensure_ascii=False))
PY

curl --fail --silent --show-error \
  -X PUT "${ERPNEXT_BASE_URL}/api/resource/Print%20Format/${ENCODED_NAME}" \
  -H "Authorization: token ${ERPNEXT_API_KEY}:${ERPNEXT_API_SECRET}" \
  -H "Content-Type: application/json" \
  --data @/tmp/print-format-payload.json

echo "Deployed: ${PRINT_FORMAT_NAME}"