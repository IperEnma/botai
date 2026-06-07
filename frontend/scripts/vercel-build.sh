#!/usr/bin/env bash
# Build Flutter web en Vercel: instala SDK stable, genera .env desde env vars, compila.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FLUTTER_HOME="${FLUTTER_HOME:-/tmp/flutter-sdk}"
if [[ ! -x "${FLUTTER_HOME}/bin/flutter" ]]; then
  echo ">> Installing Flutter (stable)..."
  rm -rf "$FLUTTER_HOME"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
fi
export PATH="${FLUTTER_HOME}/bin:${PATH}"
flutter config --enable-web --no-analytics
flutter precache --web

if [[ -z "${KONECTA_BASE_URL:-}" && -z "${API_BASE_URL:-}" && -z "${PUBLIC_BACKEND_URL:-}" ]]; then
  echo "ERROR: Define KONECTA_BASE_URL en Vercel (ej. https://tu-backend.onrender.com)" >&2
  echo "       Legacy: API_BASE_URL=https://.../api también funciona." >&2
  exit 1
fi
if [[ -z "${GOOGLE_CLIENT_ID_WEB:-}" ]]; then
  echo "ERROR: Define GOOGLE_CLIENT_ID_WEB en Vercel (mismo client ID Web de Google Cloud)" >&2
  exit 1
fi

echo ">> Writing .env for flutter_dotenv..."
cat > .env <<EOF
KONECTA_BASE_URL=${KONECTA_BASE_URL:-${PUBLIC_BACKEND_URL:-}}
API_BASE_URL=${API_BASE_URL:-}
GOOGLE_CLIENT_ID_WEB=${GOOGLE_CLIENT_ID_WEB}
GOOGLE_CLIENT_ID_ANDROID=${GOOGLE_CLIENT_ID_ANDROID:-}
GOOGLE_CLIENT_ID_IOS=${GOOGLE_CLIENT_ID_IOS:-}
AGENDA_API_BASE_URL=${AGENDA_API_BASE_URL:-}
AGENDA_PLATFORM_ADMIN=${AGENDA_PLATFORM_ADMIN:-false}
AGENDA_DEFAULT_TENANT_ID=${AGENDA_DEFAULT_TENANT_ID:-}
AGENDA_DEFAULT_USER_ID=${AGENDA_DEFAULT_USER_ID:-}
EOF

echo ">> flutter pub get && flutter build web --release (sin service worker / PWA cache)"
BUILD_ID="$(date -u +%Y%m%d%H%M%S)"
flutter pub get
flutter build web --release --pwa-strategy=none --dart-define=WEB_BUILD_ID="${BUILD_ID}"

echo "{\"buildId\":\"${BUILD_ID}\"}" > build/web/version.json
python3 scripts/inject-web-deploy-gate.py "${BUILD_ID}"
echo ">> buildId=${BUILD_ID} (ver /version.json tras deploy)"

echo ">> Build OK: build/web"
