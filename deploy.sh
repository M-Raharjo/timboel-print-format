#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${1:-build}"
MAP_FILE="${2:-print-format-map.txt}"

if [ ! -d "$BUILD_DIR" ]; then
  echo "Build directory not found: $BUILD_DIR"
  exit 1
fi

if [ ! -f "$MAP_FILE" ]; then
  echo "Map file not found: $MAP_FILE"
  exit 1
fi

if [ -z "${ERPNEXT_BASE_URL:-}" ] || [ -z "${ERPNEXT_API_KEY:-}" ] || [ -z "${ERPNEXT_API_SECRET:-}" ]; then
  echo "Missing ERPNext environment variables."
  exit 1
fi

deploy_one() {
  local print_format_name="$1"
  local html_file="$2"

  local encoded_name
  encoded_name="$(python3 - <<'PY' "$print_format_name"
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe=""))
PY
)"

  python3 - <<'PY' "$html_file" > /tmp/print-format-payload.json
import json, sys, pathlib
html = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
print(json.dumps({"html": html}, ensure_ascii=False))
PY

  curl --fail --silent --show-error --output /dev/null \
    -X PUT "${ERPNEXT_BASE_URL}/api/resource/Print%20Format/${encoded_name}" \
    -H "Authorization: token ${ERPNEXT_API_KEY}:${ERPNEXT_API_SECRET}" \
    -H "Content-Type: application/json" \
    --data @/tmp/print-format-payload.json

  echo "Deployed: ${print_format_name} <- ${html_file}"
  url="${ERPNEXT_BASE_URL}/api/resource/Print%20Format/${encoded_name}"
  echo "$url"
}

while IFS='|' read -r filename print_format_name; do
  [ -n "$filename" ] || continue
  html_file="$BUILD_DIR/$filename"

  if [ ! -f "$html_file" ]; then
    echo "Skipping missing file: $html_file"
    continue
  fi

  deploy_one "$print_format_name" "$html_file"
done < "$MAP_FILE"

echo "All done."