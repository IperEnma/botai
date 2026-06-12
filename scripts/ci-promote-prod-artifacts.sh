#!/usr/bin/env bash
# Promueve artifact de release: reutiliza JAR del CI release + build front prod.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

ARTIFACT_IN="${ARTIFACT_IN:-}"
if [[ -z "$ARTIFACT_IN" || ! -f "$ARTIFACT_IN/backend/app.jar" ]]; then
  echo "ERROR: ARTIFACT_IN debe apuntar al artifact staging (backend/app.jar)" >&2
  exit 1
fi

if [[ -z "${KONECTA_BASE_URL:-}" || -z "${GOOGLE_CLIENT_ID_WEB:-}" ]]; then
  echo "ERROR: Faltan en GitHub → Environments → production:" >&2
  [[ -z "${KONECTA_BASE_URL:-}" ]] && echo "  - Variable PROD_KONECTA_BASE_URL" >&2
  [[ -z "${GOOGLE_CLIENT_ID_WEB:-}" ]] && echo "  - Secret PROD_GOOGLE_CLIENT_ID_WEB" >&2
  exit 1
fi

DIST="$REPO_ROOT/dist/botai-build-prod"
rm -rf "$DIST"
mkdir -p "$DIST/backend" "$DIST/vercel-output"

echo ">> Backend: JAR del CI release (sin recompilar)"
cp "$ARTIFACT_IN/backend/app.jar" "$DIST/backend/app.jar"

echo ">> Frontend: flutter build web (prod env)"
bash frontend/scripts/vercel-build.sh
bash frontend/scripts/pack-vercel-prebuilt.sh
cp -r frontend/.vercel/output/. "$DIST/vercel-output/"

cat > "$DIST/manifest.json" <<EOF
{
  "sha": "${GITHUB_SHA:-unknown}",
  "ref": "${GITHUB_REF_NAME:-main}",
  "promoted_from_beta_sha": "${PROMOTED_FROM_BETA_SHA:-unknown}",
  "promoted_from_beta_tag": "${PROMOTED_FROM_BETA_TAG:-unknown}",
  "backend_jar": "backend/app.jar",
  "frontend": "vercel-output"
}
EOF

echo ">> Artifact prod listo en dist/botai-build-prod"
du -sh "$DIST/backend/app.jar" "$DIST/vercel-output"
