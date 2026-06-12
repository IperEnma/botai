#!/usr/bin/env bash
# Empaqueta artefactos CD test: JAR (reutilizado del job backend) + frontend web.
set -euo pipefail

BACKEND_JAR=""

usage() {
  echo "Uso: $0 [--backend-jar PATH]" >&2
  echo "  --backend-jar  JAR ya construido en CI (evita segundo mvn package)." >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend-jar)
      [[ $# -ge 2 ]] || usage
      BACKEND_JAR="$2"
      shift 2
      ;;
    -h|--help) usage ;;
    *) echo "Opción desconocida: $1" >&2; usage ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

DIST="$REPO_ROOT/dist/botai-build"
rm -rf "$DIST"
mkdir -p "$DIST/backend" "$DIST/vercel-output"

if [[ -n "$BACKEND_JAR" ]]; then
  [[ -f "$BACKEND_JAR" ]] || { echo "ERROR: JAR no encontrado: $BACKEND_JAR" >&2; exit 1; }
  echo ">> Backend: reutilizando JAR de CI ($BACKEND_JAR)"
  cp "$BACKEND_JAR" "$DIST/backend/app.jar"
else
  echo ">> Backend: mvn package (fallback local; en CI usar --backend-jar)" >&2
  mvn -B package -f backend/pom.xml
  JAR="$(ls backend/target/*.jar | grep -v 'original' | head -1)"
  cp "$JAR" "$DIST/backend/app.jar"
fi

if [[ -z "${KONECTA_BASE_URL:-}" || -z "${GOOGLE_CLIENT_ID_WEB:-}" ]]; then
  echo "ERROR: Faltan en GitHub → Environments → staging:" >&2
  [[ -z "${KONECTA_BASE_URL:-}" ]] && echo "  - Variable STAGING_KONECTA_BASE_URL (ej. https://botai-backend-test.onrender.com)" >&2
  [[ -z "${GOOGLE_CLIENT_ID_WEB:-}" ]] && echo "  - Secret STAGING_GOOGLE_CLIENT_ID_WEB" >&2
  exit 1
fi

echo ">> Frontend: flutter build web (staging env)"
bash frontend/scripts/vercel-build.sh
bash frontend/scripts/pack-vercel-prebuilt.sh
cp -r frontend/.vercel/output/. "$DIST/vercel-output/"

cat > "$DIST/manifest.json" <<EOF
{
  "sha": "${GITHUB_SHA:-unknown}",
  "ref": "${GITHUB_REF_NAME:-unknown}",
  "backend_jar": "backend/app.jar",
  "frontend": "vercel-output"
}
EOF

echo ">> Artifacts listos en dist/botai-build"
du -sh "$DIST/backend/app.jar" "$DIST/vercel-output"
