#!/usr/bin/env bash
# Versionado Botai: humanos eligen major (1, 2, 3); este script calcula minor/patch y tags.
#
# Tags test:  release-1.2.0-beta | hotfix-1.2.1-beta
# Tags prod:  release-1.2.0-final | hotfix-1.2.1-final
#
# Ramas: release/<major> desde develop | hotfix/<major> desde main
#
# Uso (Git Bash o Linux):
#   ./scripts/release-version.sh next release 1
#   ./scripts/release-version.sh next hotfix 1
#   ./scripts/release-version.sh branch release 1
#   ./scripts/release-version.sh tag-beta release 1.2.0
#   ./scripts/release-version.sh tag-final hotfix 1.2.1
#   ./scripts/release-version.sh tag-beta release 1.2.0 --push github

set -euo pipefail

REMOTE="${RELEASE_VERSION_REMOTE:-github}"

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

require_major() {
  if [[ ! "${1:-}" =~ ^[0-9]+$ ]]; then
    echo "ERROR: major debe ser un entero (ej. 1, 2, 3)" >&2
    exit 1
  fi
}

require_version() {
  if [[ ! "${1:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: versión debe ser MAJOR.MINOR.PATCH (ej. 1.2.0)" >&2
    exit 1
  fi
}

require_kind() {
  case "${1:-}" in
    release | hotfix) ;;
    *) echo "ERROR: kind debe ser release o hotfix" >&2; exit 1 ;;
  esac
}

# Última versión en prod para una major (solo tags *-final).
latest_final_for_major() {
  local major="$1"
  git fetch "$REMOTE" --tags --quiet 2>/dev/null || true
  {
    git tag -l "release-${major}.*-final" "hotfix-${major}.*-final"
    # Legacy: tags finales sin sufijo -final (no beta)
    git tag -l "release-${major}.*" "hotfix-${major}.*" \
      | grep -E "^(release|hotfix)-${major}\.[0-9]+\.[0-9]+$" || true
  } | sed -E 's/^(release|hotfix)-([0-9]+\.[0-9]+\.[0-9]+)(-final)?$/\2/' \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | tail -1
}

next_release_version() {
  local major="$1"
  local latest
  latest="$(latest_final_for_major "$major")"
  if [[ -z "$latest" ]]; then
    echo "${major}.0.0"
    return
  fi
  local l_major l_minor
  IFS=. read -r l_major l_minor _ <<< "$latest"
  if [[ "$l_major" != "$major" ]]; then
    echo "${major}.0.0"
    return
  fi
  echo "${major}.$((l_minor + 1)).0"
}

next_hotfix_version() {
  local major="$1"
  local latest
  latest="$(latest_final_for_major "$major")"
  if [[ -z "$latest" ]]; then
    echo "ERROR: no hay release *-final en major ${major}; no se puede calcular hotfix." >&2
    exit 1
  fi
  local l_major l_minor l_patch
  IFS=. read -r l_major l_minor l_patch <<< "$latest"
  if [[ "$l_major" != "$major" ]]; then
    echo "ERROR: último final ${latest} no coincide con major ${major}." >&2
    exit 1
  fi
  echo "${major}.${l_minor}.$((l_patch + 1))"
}

cmd_next() {
  require_kind "$1"
  require_major "$2"
  if [[ "$1" == "release" ]]; then
    next_release_version "$2"
  else
    next_hotfix_version "$2"
  fi
}

cmd_branch() {
  require_kind "$1"
  require_major "$2"
  local branch="$1/$2"
  if [[ "$1" == "release" ]]; then
    git checkout develop
    git pull "$REMOTE" develop
    git checkout -B "$branch"
    echo "Rama $branch creada desde develop. Commiteá, luego: $0 tag-beta release <versión>"
  else
    git checkout main
    git pull "$REMOTE" main
    git checkout -B "$branch"
    echo "Rama $branch creada desde main. Commiteá el fix, luego: $0 tag-beta hotfix <versión>"
  fi
}

cmd_tag() {
  local suffix="$1" # beta | final
  shift
  require_kind "${1:-}"
  require_version "${2:-}"
  local kind="$1"
  local version="$2"
  shift 2
  local tag="${kind}-${version}-${suffix}"

  if [[ "$suffix" == "final" ]]; then
    git checkout main
    git pull "$REMOTE" main
  fi

  if git rev-parse "$tag" >/dev/null 2>&1; then
    echo "ERROR: el tag $tag ya existe" >&2
    exit 1
  fi

  git tag -a "$tag" -m "${kind} ${version} ${suffix}"
  echo "Tag creado: $tag"

  if [[ "${1:-}" == "--push" ]]; then
    local remote="${2:-$REMOTE}"
    git push "$remote" "$tag"
    echo "Pusheado a $remote"
  fi
}

main() {
  [[ $# -ge 1 ]] || usage
  case "$1" in
    next)
      [[ $# -eq 3 ]] || usage
      cmd_next "$2" "$3"
      ;;
    branch)
      [[ $# -eq 3 ]] || usage
      cmd_branch "$2" "$3"
      ;;
    tag-beta)
      [[ $# -ge 4 ]] || usage
      cmd_tag beta "$2" "$3" "${@:4}"
      ;;
    tag-final)
      [[ $# -ge 4 ]] || usage
      cmd_tag final "$2" "$3" "${@:4}"
      ;;
    -h | --help) usage ;;
    *) usage ;;
  esac
}

main "$@"
