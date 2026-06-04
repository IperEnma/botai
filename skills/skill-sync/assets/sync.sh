#!/usr/bin/env bash
# Sync skill metadata to AGENTS.md (Available Skills + Auto-invoke tables) — Prowler-style
# Usage: ./sync.sh [--dry-run] [--scope SCOPE]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
SKILLS_DIR="$REPO_ROOT/skills"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
FILTER_SCOPE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --scope) FILTER_SCOPE="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [--scope root|backend|frontend]"
      exit 0
      ;;
    *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
  esac
done

get_agents_path() {
  case "$1" in
    root) echo "$REPO_ROOT/AGENTS.md" ;;
    backend) echo "$REPO_ROOT/backend/AGENTS.md" ;;
    frontend) echo "$REPO_ROOT/frontend/AGENTS.md" ;;
    *) echo "" ;;
  esac
}

skill_link_path() {
  local scope="$1"
  local skill_name="$2"
  case "$scope" in
    root) echo "skills/${skill_name}/SKILL.md" ;;
    backend|frontend) echo "../skills/${skill_name}/SKILL.md" ;;
    *) echo "skills/${skill_name}/SKILL.md" ;;
  esac
}

extract_field() {
  local file="$1"
  local field="$2"
  awk -v field="$field" '
    /^---$/ { in_frontmatter = !in_frontmatter; next }
    in_frontmatter && $1 == field":" {
      sub(/^[^:]+:[[:space:]]*/, "")
      if ($0 != "" && $0 != ">") {
        gsub(/^["'\'']|["'\'']$/, "")
        print
        exit
      }
      getline
      while (/^[[:space:]]/ && !/^---$/) {
        sub(/^[[:space:]]+/, "")
        printf "%s ", $0
        if (!getline) break
      }
      print ""
      exit
    }
  ' "$file" | sed 's/[[:space:]]*$//'
}

short_description() {
  local raw="$1"
  echo "$raw" | head -n1 | sed 's/Trigger:.*//' | sed 's/[[:space:]]*$//' | cut -c1-120
}

extract_metadata() {
  local file="$1"
  local field="$2"
  awk -v field="$field" '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }
    /^---$/ { in_frontmatter = !in_frontmatter; next }
    in_frontmatter && /^metadata:/ { in_metadata = 1; next }
    in_frontmatter && in_metadata && /^[a-z]/ && !/^[[:space:]]/ { in_metadata = 0 }
    in_frontmatter && in_metadata && $1 == field":" {
      sub(/^[^:]+:[[:space:]]*/, "")
      if ($0 != "") {
        v = $0
        gsub(/^["'\'']|["'\'']$/, "", v)
        gsub(/^\[|\]$/, "", v)
        print trim(v)
        exit
      }
      out = ""
      while (getline) {
        if (!in_frontmatter) break
        if (!in_metadata) break
        if ($0 ~ /^[a-z]/ && $0 !~ /^[[:space:]]/) break
        line = $0
        if (line ~ /^---$/) break
        if (line ~ /^[[:space:]]*-[[:space:]]*/) {
          sub(/^[[:space:]]*-[[:space:]]*/, "", line)
          line = trim(line)
          gsub(/^["'\'']|["'\'']$/, "", line)
          if (line != "") {
            if (out == "") out = line
            else out = out "|" line
          }
        } else { break }
      }
      if (out != "") print out
      exit
    }
  ' "$file"
}

echo -e "${BLUE}Botai Skill Sync${NC}"
echo "=================="
echo ""

SCOPE_TMPDIR=$(mktemp -d)
CATALOG_TMPDIR=$(mktemp -d)
trap 'rm -rf "$SCOPE_TMPDIR" "$CATALOG_TMPDIR"' EXIT

while IFS= read -r skill_file; do
  [ -f "$skill_file" ] || continue
  skill_name=$(extract_field "$skill_file" "name")
  description=$(extract_field "$skill_file" "description")
  scope_raw=$(extract_metadata "$skill_file" "scope")
  auto_invoke_raw=$(extract_metadata "$skill_file" "auto_invoke")
  auto_invoke=$(echo "$auto_invoke_raw" | sed 's/|/;;/g')
  desc_short=$(short_description "$description")

  # Root catalog lists every skill (Prowler-style); scoped AGENTS.md only lists matching scope.
  if [ -z "$FILTER_SCOPE" ] || [ "$FILTER_SCOPE" = "root" ]; then
    printf "%s\t%s\t%s\n" "$skill_name" "$desc_short" "$(skill_link_path "root" "$skill_name")" \
      >> "$CATALOG_TMPDIR/root"
  fi

  echo "$scope_raw" | tr ', ' '\n' | while read -r scope; do
    scope=$(echo "$scope" | tr -d '[:space:]')
    [ -z "$scope" ] && continue
    [ -n "$FILTER_SCOPE" ] && [ "$scope" != "$FILTER_SCOPE" ] && continue

    if [ "$scope" != "root" ]; then
      printf "%s\t%s\t%s\n" "$skill_name" "$desc_short" "$(skill_link_path "$scope" "$skill_name")" \
        >> "$CATALOG_TMPDIR/$scope"
    fi

    [ -z "$auto_invoke" ] && continue
    echo "$skill_name:$auto_invoke" >> "$SCOPE_TMPDIR/$scope"
  done
done < <(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -name SKILL.md -print | sort)

for scope in root backend frontend; do
  [ -n "$FILTER_SCOPE" ] && [ "$scope" != "$FILTER_SCOPE" ] && continue
  [ -f "$CATALOG_TMPDIR/$scope" ] || [ -f "$SCOPE_TMPDIR/$scope" ] || continue
  agents_path=$(get_agents_path "$scope")
  if [ -z "$agents_path" ] || [ ! -f "$agents_path" ]; then
    echo -e "${YELLOW}Warning: No AGENTS.md for scope '$scope'${NC}"
    continue
  fi

  echo -e "${BLUE}Processing: $scope -> $agents_path${NC}"

  # --- Available Skills (Prowler: Skill | Description | Path) ---
  if [ "$scope" = "root" ]; then
    available_section="## Available Skills

| Skill | Description | Path |"
  else
    available_section="## Available Skills

| Skill | Description | Path |"
  fi

  catalog_file="$CATALOG_TMPDIR/$scope"
  if [ -f "$catalog_file" ]; then
    catalog_rows=$(mktemp)
    sort -u "$catalog_file" > "${catalog_file}.sorted"
    while IFS=$'\t' read -r skill_name desc_short link_path; do
      [ -z "$skill_name" ] && continue
      printf "%s\t%s\t%s\n" "$skill_name" "$desc_short" "$link_path" >> "$catalog_rows"
    done < "${catalog_file}.sorted"
    while IFS=$'\t' read -r skill_name desc_short link_path; do
      [ -z "$skill_name" ] && continue
      available_section="$available_section
| \`$skill_name\` | ${desc_short:-—} | [SKILL.md]($link_path) |"
    done < <(LC_ALL=C sort -t $'\t' -k1,1 "$catalog_rows")
    rm -f "$catalog_rows" "${catalog_file}.sorted"
  fi

  # --- Auto-invoke (Action | Skill) ---
  auto_invoke_section="### Auto-invoke Skills

When performing these actions, ALWAYS invoke the corresponding skill FIRST:

| Action | Skill |
|--------|-------|"

  invoke_file="$SCOPE_TMPDIR/$scope"
  if [ -f "$invoke_file" ]; then
    rows_file=$(mktemp)
    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      skill_name="${entry%%:*}"
      actions_raw=$(echo "${entry#*:}" | sed 's/;;/|/g')
      echo "$actions_raw" | tr '|' '\n' | while read -r action; do
        action=$(echo "$action" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        [ -z "$action" ] && continue
        printf "%s\t%s\n" "$action" "$skill_name" >> "$rows_file"
      done
    done < "$invoke_file"
    while IFS=$'\t' read -r action skill_name; do
      [ -z "$action" ] && continue
      auto_invoke_section="$auto_invoke_section
| $action | \`$skill_name\` |"
    done < <(LC_ALL=C sort -t $'\t' -k1,1 -k2,2 "$rows_file")
    rm -f "$rows_file"
  fi

  if $DRY_RUN; then
    echo -e "${YELLOW}[DRY RUN] Would update $agents_path${NC}"
    echo "$available_section"
    echo ""
    echo "$auto_invoke_section"
    echo ""
    continue
  fi

  avail_file=$(mktemp)
  invoke_file_out=$(mktemp)
  echo "$available_section" > "$avail_file"
  echo "$auto_invoke_section" > "$invoke_file_out"

  if grep -q "## Available Skills" "$agents_path"; then
    if [ "$scope" = "root" ]; then
      end_avail='^## Available Subagents'
    else
      end_avail='^### Auto-invoke Skills'
    fi
    awk -v end_pat="$end_avail" '
      /^## Available Skills/ {
        while ((getline line < "'"$avail_file"'") > 0) print line
        close("'"$avail_file"'")
        print ""
        skip = 1
        next
      }
      skip && $0 ~ end_pat { skip = 0 }
      !skip { print }
    ' "$agents_path" > "$agents_path.tmp"
    mv "$agents_path.tmp" "$agents_path"
  fi

  if grep -q "### Auto-invoke Skills" "$agents_path"; then
    awk '
      /^### Auto-invoke Skills/ {
        while ((getline line < "'"$invoke_file_out"'") > 0) print line
        close("'"$invoke_file_out"'")
        skip = 1
        next
      }
      skip && /^(---|## )/ { skip = 0; print "" }
      !skip { print }
    ' "$agents_path" > "$agents_path.tmp"
    mv "$agents_path.tmp" "$agents_path"
  else
    awk '
      /^## Available Subagents/ && !inserted {
        while ((getline line < "'"$invoke_file_out"'") > 0) print line
        close("'"$invoke_file_out"'")
        print ""
        inserted = 1
        print
        next
      }
      { print }
    ' "$agents_path" > "$agents_path.tmp"
    mv "$agents_path.tmp" "$agents_path"
  fi

  rm -f "$avail_file" "$invoke_file_out"
  echo -e "${GREEN}  ✓ Updated Available Skills + Auto-invoke${NC}"
done

echo ""
echo -e "${GREEN}Done!${NC}"

echo ""
echo -e "${BLUE}Skills missing sync metadata (scope and/or auto_invoke):${NC}"
missing=0
while IFS= read -r skill_file; do
  [ -f "$skill_file" ] || continue
  skill_name=$(extract_field "$skill_file" "name")
  scope_raw=$(extract_metadata "$skill_file" "scope")
  auto_invoke_raw=$(extract_metadata "$skill_file" "auto_invoke")
  if [ -z "$scope_raw" ] || [ -z "$auto_invoke_raw" ]; then
    echo -e "  ${YELLOW}$skill_name${NC} — missing: ${scope_raw:-scope} ${auto_invoke_raw:-auto_invoke}"
    missing=$((missing + 1))
  fi
done < <(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -name SKILL.md -print | sort)

if [ $missing -eq 0 ]; then
  echo -e "  ${GREEN}All skills have scope + auto_invoke${NC}"
fi
