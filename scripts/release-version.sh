#!/usr/bin/env bash
# Versionado Botai: humanos eligen major (1, 2, 3); este script calcula minor/patch y tags.
#
# Tags test:  release-1.2.0-beta | hotfix-1.2.1-beta
# Tags prod:  release-1.2.0-final | hotfix-1.2.1-final
#
# Ramas plantilla: release/<major>.x.x-beta | hotfix/<major>.x.x-beta
# El CI calcula minor/patch y crea el tag *-beta; el CD test es manual con ese tag.
#
# Uso (Git Bash o Linux):
#   ./scripts/release-version.sh next release 1
#   ./scripts/release-version.sh next hotfix 1
#   ./scripts/release-version.sh branch release 1
#   ./scripts/release-version.sh tag-beta-from-branch --push origin
#   ./scripts/release-version.sh tag-final release 1.2.0 --push github

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

parse_template_beta_branch() {
  local branch="$1"
  if [[ "$branch" =~ ^(release|hotfix)/([0-9]+)\.x\.x-beta$ ]]; then
    echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    return 0
  fi
  echo "ERROR: rama debe ser release/<major>.x.x-beta o hotfix/<major>.x.x-beta (ej. release/1.x.x-beta)" >&2
  return 1
}

cmd_branch() {
  require_kind "$1"
  require_major "$2"
  local branch="$1/${2}.x.x-beta"
  if [[ "$1" == "release" ]]; then
    git checkout develop
    git pull "$REMOTE" develop
    git checkout -B "$branch"
    echo "Rama $branch creada desde develop."
    echo "Push → CI crea el tag beta. Luego: Actions → Deploy test → Run workflow (con ese tag)."
  else
    git checkout main
    git pull "$REMOTE" main
    git checkout -B "$branch"
    echo "Rama $branch creada desde main."
    echo "Push → CI crea el tag beta. Luego: Actions → Deploy test → Run workflow (con ese tag)."
  fi
}

cmd_tag_beta_from_branch() {
  local branch="${GITHUB_REF_NAME:-}"
  local push_remote=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --push)
        push_remote="${2:-$REMOTE}"
        shift 2
        ;;
      *)
        branch="$1"
        shift
        ;;
    esac
  done

  local kind major
  read -r kind major < <(parse_template_beta_branch "$branch")
  local version tag
  version="$(cmd_next "$kind" "$major")"
  tag="${kind}-${version}-beta"

  local current_sha
  current_sha="$(git rev-parse HEAD)"
  if git rev-parse "$tag" >/dev/null 2>&1; then
    local existing_sha
    existing_sha="$(git rev-parse "$tag^{commit}")"
    if [[ "$existing_sha" == "$current_sha" ]]; then
      echo "Tag ya existe en este commit: $tag"
      echo "tag=$tag"
      return 0
    fi
    echo "ERROR: $tag ya existe en otro commit ($existing_sha). Borrá el tag o usá otra versión." >&2
    exit 1
  fi

  if [[ -z "$(git config user.email 2>/dev/null)" ]]; then
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git config user.name "github-actions[bot]"
  fi

  git tag -a "$tag" -m "${kind} ${version} beta (${branch})"
  echo "Tag creado: $tag"
  echo "tag=$tag"

  if [[ -n "$push_remote" ]]; then
    git push "$push_remote" "$tag"
    echo "Pusheado a $push_remote"
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
    tag-beta-from-branch)
      shift
      cmd_tag_beta_from_branch "$@"
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
