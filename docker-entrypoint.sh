#!/bin/sh
set -eu

if command -v soffice >/dev/null 2>&1; then
  SOFFICE_BIN="$(command -v soffice)"
  OFFICE_HOME="$(cd "$(dirname "$SOFFICE_BIN")/.." && pwd)"
else
  echo "LibreOffice executable 'soffice' not found; kkFileView cannot start." >&2
  exit 1
fi

exec java \
  -Doffice.home="${OFFICE_HOME}" \
  -jar /app/kkFileView.jar
