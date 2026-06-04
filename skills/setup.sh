#!/bin/bash
# Setup AI Skills for botai (Prowler-style)
# Usage: ./skills/setup.sh [--all|--claude|--codex|--copilot|--gemini]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_SOURCE="$SCRIPT_DIR"
AGENTS_SOURCE="$REPO_ROOT/agents"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SETUP_CLAUDE=false
SETUP_GEMINI=false
SETUP_CODEX=false
SETUP_COPILOT=false

add_to_gitignore() {
  local pattern="$1"
  local gitignore_file="$REPO_ROOT/.gitignore"
  local header="# AI coding assistants (generated symlinks)"
  if [ ! -f "$gitignore_file" ]; then touch "$gitignore_file"; fi
  if ! grep -qxF "$pattern" "$gitignore_file" 2>/dev/null; then
    if ! grep -qxF "$header" "$gitignore_file" 2>/dev/null; then
      printf "\n%s\n" "$header" >> "$gitignore_file"
    fi
    echo "$pattern" >> "$gitignore_file"
    echo -e "${GREEN}  Added $pattern to .gitignore${NC}"
  fi
}

link_dir() {
  local target="$1"
  local source="$2"
  mkdir -p "$(dirname "$target")"
  if [ -L "$target" ]; then rm "$target"
  elif [ -e "$target" ]; then mv "$target" "${target}.backup.$(date +%s)"
  fi
  ln -s "$source" "$target"
}

link_agents_md() {
  local target_name="$1"
  local count=0
  while IFS= read -r agents_file; do
    agents_dir=$(dirname "$agents_file")
    (cd "$agents_dir" && ln -sf "$(basename "$agents_file")" "$target_name")
    count=$((count + 1))
  done < <(find "$REPO_ROOT" -name "AGENTS.md" \
    -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)
  echo -e "${GREEN}  Linked $count AGENTS.md -> $target_name${NC}"
}

setup_claude() {
  link_dir "$REPO_ROOT/.claude/skills" "$SKILLS_SOURCE"
  echo -e "${GREEN}  .claude/skills -> skills/${NC}"
  link_dir "$REPO_ROOT/.cursor/skills" "$SKILLS_SOURCE" 2>/dev/null || true
  if [ -L "$REPO_ROOT/.cursor/skills" ]; then
    echo -e "${GREEN}  .cursor/skills -> skills/${NC}"
    add_to_gitignore ".cursor/skills"
  fi
  if [ -d "$AGENTS_SOURCE" ]; then
    link_dir "$REPO_ROOT/.claude/agents" "$AGENTS_SOURCE"
    echo -e "${GREEN}  .claude/agents -> agents/${NC}"
  fi
  add_to_gitignore ".claude/skills"
  add_to_gitignore ".claude/agents"
  link_agents_md "CLAUDE.md"
  add_to_gitignore "CLAUDE.md"
}

setup_gemini() {
  link_dir "$REPO_ROOT/.gemini/skills" "$SKILLS_SOURCE"
  echo -e "${GREEN}  .gemini/skills -> skills/${NC}"
  link_agents_md "GEMINI.md"
  add_to_gitignore "GEMINI.md"
}

setup_codex() {
  link_dir "$REPO_ROOT/.codex/skills" "$SKILLS_SOURCE"
  echo -e "${GREEN}  .codex/skills -> skills/${NC}"
  echo -e "${GREEN}  Codex uses AGENTS.md natively${NC}"
}

setup_copilot() {
  if [ -f "$REPO_ROOT/AGENTS.md" ]; then
    mkdir -p "$REPO_ROOT/.github"
    ln -sf "../AGENTS.md" "$REPO_ROOT/.github/copilot-instructions.md"
    echo -e "${GREEN}  AGENTS.md -> .github/copilot-instructions.md${NC}"
    add_to_gitignore ".github/copilot-instructions.md"
  fi
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --all) SETUP_CLAUDE=true; SETUP_GEMINI=true; SETUP_CODEX=true; SETUP_COPILOT=true ;;
    --claude) SETUP_CLAUDE=true ;;
    --gemini) SETUP_GEMINI=true ;;
    --codex) SETUP_CODEX=true ;;
    --copilot) SETUP_COPILOT=true ;;
    --help|-h)
      echo "Usage: $0 [--all|--claude|--codex|--copilot|--gemini]"
      exit 0
      ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
  shift
done

if ! $SETUP_CLAUDE && ! $SETUP_GEMINI && ! $SETUP_CODEX && ! $SETUP_COPILOT; then
  SETUP_CLAUDE=true
fi

SKILL_COUNT=$(find "$SKILLS_SOURCE" -maxdepth 2 -name "SKILL.md" | wc -l | tr -d ' ')
echo -e "${BLUE}Botai AI Skills Setup ($SKILL_COUNT skills)${NC}"
echo ""

$SETUP_CLAUDE && setup_claude
$SETUP_GEMINI && setup_gemini
$SETUP_CODEX && setup_codex
$SETUP_COPILOT && setup_copilot

echo ""
echo -e "${GREEN}Done. Restart your AI assistant.${NC}"
echo -e "${BLUE}Regenerate Auto-invoke: ./skills/skill-sync/assets/sync.sh${NC}"
