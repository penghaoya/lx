#!/bin/sh
set -eu

# Try to find LibreOffice
if command -v soffice >/dev/null 2>&1; then
  SOFFICE_BIN="$(command -v soffice)"
  OFFICE_HOME="$(cd "$(dirname "$SOFFICE_BIN")/.." && pwd)"
  echo "LibreOffice found at: ${OFFICE_HOME}"
  OFFICE_ARGS="-Doffice.home=${OFFICE_HOME}"
else
  echo "WARNING: LibreOffice executable 'soffice' not found."
  echo "Document conversion features will not be available."
  echo "kkFileView will start in limited mode."
  OFFICE_ARGS=""
fi

# Start kkFileView
echo "Starting kkFileView..."
exec java ${OFFICE_ARGS} -jar /app/kkFileView.jar
