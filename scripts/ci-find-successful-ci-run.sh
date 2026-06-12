#!/usr/bin/env bash
# Imprime el run id de CI exitoso para un commit (uso en CD test / CD prod).
set -euo pipefail

SHA="${1:-}"
WORKFLOW_FILE="${WORKFLOW_FILE:-ci-test.yml}"
if [[ -z "$SHA" ]]; then
  echo "Uso: WORKFLOW_FILE=ci-test.yml $0 <commit-sha>" >&2
  exit 1
fi

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY requerido}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN requerido}"

OWNER="${GITHUB_REPOSITORY%%/*}"
REPO="${GITHUB_REPOSITORY##*/}"

RUN_ID="$(
  curl -fsS \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/${WORKFLOW_FILE}/runs?head_sha=${SHA}&status=completed&per_page=20" \
    | python3 -c "
import json, sys
runs = json.load(sys.stdin).get('workflow_runs', [])
for r in runs:
    if r.get('conclusion') == 'success':
        print(r['id'])
        break
"
)"

if [[ -z "$RUN_ID" ]]; then
  echo "ERROR: no hay run de CI exitoso con artifacts para commit ${SHA}" >&2
  exit 1
fi

echo "$RUN_ID"
