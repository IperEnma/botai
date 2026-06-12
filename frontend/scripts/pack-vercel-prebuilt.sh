#!/usr/bin/env bash
# Empaqueta build/web como .vercel/output para `vercel deploy --prebuilt`.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${1:-$ROOT/.vercel/output}"

if [[ ! -d "$ROOT/build/web" ]]; then
  echo "ERROR: falta $ROOT/build/web (corré vercel-build.sh antes)" >&2
  exit 1
fi

mkdir -p "$OUT_DIR/static"
cp -r "$ROOT/build/web/." "$OUT_DIR/static/"

cat > "$OUT_DIR/config.json" <<'EOF'
{
  "version": 3,
  "routes": [
    { "handle": "filesystem" },
    {
      "src": "/(.*)",
      "dest": "/index.html",
      "check": true
    }
  ]
}
EOF

echo ">> Vercel prebuilt output: $OUT_DIR"
