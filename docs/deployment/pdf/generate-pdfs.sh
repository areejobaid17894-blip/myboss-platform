#!/usr/bin/env bash
# Generate HTML + PDF guides for DevOps, Apigee, testing, and Android Studio
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> my boss app — PDF guide generator"
python3 md_to_html.py

CHROME=""
for candidate in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium" \
  "google-chrome" \
  "chromium"; do
  if command -v "$candidate" >/dev/null 2>&1 || [ -x "$candidate" ]; then
    CHROME="$candidate"
    break
  fi
done

if [ -z "$CHROME" ]; then
  echo ""
  echo "Chrome not found. HTML files are ready in: $SCRIPT_DIR"
  echo "Open each .html in a browser → Print → Save as PDF"
  exit 0
fi

echo "==> Generating PDFs with Chrome..."
for html in *.html; do
  [ -f "$html" ] || continue
  pdf="${html%.html}.pdf"
  "$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$SCRIPT_DIR/$pdf" \
    "file://$SCRIPT_DIR/$html" 2>/dev/null
  echo "  PDF: $pdf"
done

echo ""
echo "Done. Files in: $SCRIPT_DIR"
ls -1 "$SCRIPT_DIR"/*.pdf 2>/dev/null || true
