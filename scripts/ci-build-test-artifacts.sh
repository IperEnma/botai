#!/usr/bin/env bash
# Build único para CD test: backend JAR + frontend web (mismo commit que pasó CI).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

DIST="$REPO_ROOT/dist/botai-build"
rm -rf "$DIST"
mkdir -p "$DIST/backend" "$DIST/vercel-output"

echo ">> Backend: mvn package (tests ya corrieron en CI)"
mvn -B -DskipTests package -f backend/pom.xml
JAR="$(ls backend/target/*.jar | grep -v 'original' | head -1)"
cp "$JAR" "$DIST/backend/app.jar"

if [[ -z "${KONECTA_BASE_URL:-}" || -z "${GOOGLE_CLIENT_ID_WEB:-}" ]]; then
  echo "ERROR: KONECTA_BASE_URL y GOOGLE_CLIENT_ID_WEB requeridos (environment staging)" >&2
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
