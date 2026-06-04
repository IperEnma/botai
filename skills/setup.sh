#!/bin/bash
# Setup AI Skills for botai development
# Configures AI coding assistants that follow the agentskills.io standard:
# - Claude Code: .claude/skills/ (symlink) + CLAUDE.md (symlink)
# - Cursor IDE:  .cursor/skills/ (symlink) — botai extension
# - OpenCode:    same as Claude (.claude/skills)
# - Codex:       .codex/skills/ (symlink)
# - GitHub Copilot: .github/copilot-instructions.md (symlink)
# - Gemini CLI:  .gemini/skills/ (symlink) + GEMINI.md (symlink)
#
# Usage:
#   ./skills/setup.sh              # Interactive mode (select assistants)
#   ./skills/setup.sh --all        # Configure all assistants
#   ./skills/setup.sh --claude     # Configure only Claude Code (+ Cursor + agents)
#   ./skills/setup.sh --claude --codex

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_SOURCE="$SCRIPT_DIR"
AGENTS_SOURCE="$REPO_ROOT/agents"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SETUP_CLAUDE=false
SETUP_GEMINI=false
SETUP_CODEX=false
SETUP_COPILOT=false

# =============================================================================
# HELPERS
# =============================================================================

add_to_gitignore() {
  local pattern="$1"
  local gitignore_file="$REPO_ROOT/.gitignore"
  local header="# AI Coding assistants assets"

  if [ ! -f "$gitignore_file" ]; then
    touch "$gitignore_file"
  fi

  if ! grep -qxF "$pattern" "$gitignore_file" 2>/dev/null; then
    if ! grep -qxF "$header" "$gitignore_file" 2>/dev/null; then
      echo -e "\n\n$header" >> "$gitignore_file"
    fi
    echo "$pattern" >> "$gitignore_file"
    echo -e "${GREEN}  ✓ Added $pattern to .gitignore${NC}"
  fi
}

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Configure AI coding assistants for botai development."
  echo ""
  echo "Options:"
  echo "  --all       Configure all assistants"
  echo "  --claude    Claude Code (+ Cursor skills + agents symlinks)"
  echo "  --gemini    Gemini CLI"
  echo "  --codex     Codex (OpenAI)"
  echo "  --copilot   GitHub Copilot"
  echo "  --help      Show this help message"
  echo ""
  echo "If no options are provided, runs in interactive mode."
  echo ""
  echo "Examples:"
  echo "  $0                    # Interactive selection"
  echo "  $0 --all              # All assistants"
  echo "  $0 --claude --codex   # Claude and Codex only"
}

show_menu() {
  echo -e "${BOLD}Which AI assistants do you use?${NC}"
  echo -e "${CYAN}(Use numbers to toggle, Enter to confirm)${NC}"
  echo ""

  local options=("Claude Code / Cursor" "Gemini CLI" "Codex (OpenAI)" "GitHub Copilot")
  local selected=(true false false false)

  while true; do
    for i in "${!options[@]}"; do
      if [ "${selected[$i]}" = true ]; then
        echo -e "  ${GREEN}[x]${NC} $((i + 1)). ${options[$i]}"
      else
        echo -e "  [ ] $((i + 1)). ${options[$i]}"
      fi
    done
    echo ""
    echo -e "  ${YELLOW}a${NC}. Select all"
    echo -e "  ${YELLOW}n${NC}. Select none"
    echo ""
    echo -n "Toggle (1-4, a, n) or Enter to confirm: "

    read -r choice

    case $choice in
      1) selected[0]=$([ "${selected[0]}" = true ] && echo false || echo true) ;;
      2) selected[1]=$([ "${selected[1]}" = true ] && echo false || echo true) ;;
      3) selected[2]=$([ "${selected[2]}" = true ] && echo false || echo true) ;;
      4) selected[3]=$([ "${selected[3]}" = true ] && echo false || echo true) ;;
      a|A) selected=(true true true true) ;;
      n|N) selected=(false false false false) ;;
      "") break ;;
      *) echo -e "${RED}Invalid option${NC}" ;;
    esac

    echo -en "\033[10A\033[J"
  done

  SETUP_CLAUDE=${selected[0]}
  SETUP_GEMINI=${selected[1]}
  SETUP_CODEX=${selected[2]}
  SETUP_COPILOT=${selected[3]}
}

setup_claude() {
  local target="$REPO_ROOT/.claude/skills"

  if [ ! -d "$REPO_ROOT/.claude" ]; then
    mkdir -p "$REPO_ROOT/.claude"
  fi
  add_to_gitignore ".claude/skills"

  if [ -L "$target" ]; then
    rm "$target"
  elif [ -d "$target" ]; then
    mv "$target" "$REPO_ROOT/.claude/skills.backup.$(date +%s)"
  fi

  ln -s "$SKILLS_SOURCE" "$target"
  echo -e "${GREEN}  ✓ .claude/skills -> skills/${NC}"

  # Cursor IDE (same skills folder)
  local cursor_target="$REPO_ROOT/.cursor/skills"
  if [ ! -d "$REPO_ROOT/.cursor" ]; then
    mkdir -p "$REPO_ROOT/.cursor"
  fi
  add_to_gitignore ".cursor/skills"
  if [ -L "$cursor_target" ]; then
    rm "$cursor_target"
  elif [ -d "$cursor_target" ]; then
    mv "$cursor_target" "$REPO_ROOT/.cursor/skills.backup.$(date +%s)"
  fi
  ln -s "$SKILLS_SOURCE" "$cursor_target"
  echo -e "${GREEN}  ✓ .cursor/skills -> skills/${NC}"

  # Subagents (botai)
  if [ -d "$AGENTS_SOURCE" ]; then
    local agents_target="$REPO_ROOT/.claude/agents"
    add_to_gitignore ".claude/agents"
    if [ -L "$agents_target" ]; then
      rm "$agents_target"
    elif [ -d "$agents_target" ]; then
      mv "$agents_target" "$REPO_ROOT/.claude/agents.backup.$(date +%s)"
    fi
    ln -s "$AGENTS_SOURCE" "$agents_target"
    echo -e "${GREEN}  ✓ .claude/agents -> agents/${NC}"
  fi

  link_agents_md "CLAUDE.md"
}

setup_gemini() {
  local target="$REPO_ROOT/.gemini/skills"

  if [ ! -d "$REPO_ROOT/.gemini" ]; then
    mkdir -p "$REPO_ROOT/.gemini"
  fi
  add_to_gitignore ".gemini/skills"

  if [ -L "$target" ]; then
    rm "$target"
  elif [ -d "$target" ]; then
    mv "$target" "$REPO_ROOT/.gemini/skills.backup.$(date +%s)"
  fi

  ln -s "$SKILLS_SOURCE" "$target"
  echo -e "${GREEN}  ✓ .gemini/skills -> skills/${NC}"

  link_agents_md "GEMINI.md"
}

setup_codex() {
  local target="$REPO_ROOT/.codex/skills"

  if [ ! -d "$REPO_ROOT/.codex" ]; then
    mkdir -p "$REPO_ROOT/.codex"
  fi
  add_to_gitignore ".codex/skills"

  if [ -L "$target" ]; then
    rm "$target"
  elif [ -d "$target" ]; then
    mv "$target" "$REPO_ROOT/.codex/skills.backup.$(date +%s)"
  fi

  ln -s "$SKILLS_SOURCE" "$target"
  echo -e "${GREEN}  ✓ .codex/skills -> skills/${NC}"
  echo -e "${GREEN}  ✓ Codex uses AGENTS.md natively${NC}"
}

setup_copilot() {
  if [ -f "$REPO_ROOT/AGENTS.md" ]; then
    mkdir -p "$REPO_ROOT/.github"

    local target="$REPO_ROOT/.github/copilot-instructions.md"
    ln -sf "../AGENTS.md" "$target"

    echo -e "${GREEN}  ✓ AGENTS.md -> .github/copilot-instructions.md${NC}"
    add_to_gitignore ".github/copilot-instructions.md"
  fi
}

link_agents_md() {
  local target_name="$1"
  local agents_files
  local linked=0
  local skipped=0

  agents_files=$(find "$REPO_ROOT" -name "AGENTS.md" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

  for agents_file in $agents_files; do
    local agents_dir link_path
    agents_dir=$(dirname "$agents_file")
    link_path="$agents_dir/$target_name"
    if [ "$agents_dir" = "$REPO_ROOT" ]; then
      skipped=$((skipped + 1))
      continue
    fi
    if [ -e "$link_path" ] && [ ! -L "$link_path" ]; then
      skipped=$((skipped + 1))
      continue
    fi
    (cd "$agents_dir" && ln -sf "$(basename "$agents_file")" "$target_name")
    linked=$((linked + 1))
  done

  if [ "$linked" -gt 0 ]; then
    echo -e "${GREEN}  ✓ Linked $linked AGENTS.md -> $target_name${NC}"
  fi
  if [ "$skipped" -gt 0 ]; then
    echo -e "${YELLOW}  ⊘ Skipped $skipped existing $target_name (e.g. root CLAUDE.md)${NC}"
  fi
}

# =============================================================================
# PARSE ARGUMENTS
# =============================================================================

while [[ $# -gt 0 ]]; do
  case $1 in
    --all)
      SETUP_CLAUDE=true
      SETUP_GEMINI=true
      SETUP_CODEX=true
      SETUP_COPILOT=true
      shift
      ;;
    --claude)
      SETUP_CLAUDE=true
      shift
      ;;
    --gemini)
      SETUP_GEMINI=true
      shift
      ;;
    --codex)
      SETUP_CODEX=true
      shift
      ;;
    --copilot)
      SETUP_COPILOT=true
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      show_help
      exit 1
      ;;
  esac
done

# =============================================================================
# MAIN
# =============================================================================

echo "🤖 Botai AI Skills Setup"
echo "========================"
echo ""

SKILL_COUNT=$(find "$SKILLS_SOURCE" -maxdepth 2 -name "SKILL.md" | wc -l | tr -d ' ')

if [ "$SKILL_COUNT" -eq 0 ]; then
  echo -e "${RED}No skills found in $SKILLS_SOURCE${NC}"
  exit 1
fi

echo -e "${BLUE}Found $SKILL_COUNT skills to configure${NC}"
echo ""

if [ "$SETUP_CLAUDE" = false ] && [ "$SETUP_GEMINI" = false ] && [ "$SETUP_CODEX" = false ] && [ "$SETUP_COPILOT" = false ]; then
  show_menu
  echo ""
fi

if [ "$SETUP_CLAUDE" = false ] && [ "$SETUP_GEMINI" = false ] && [ "$SETUP_CODEX" = false ] && [ "$SETUP_COPILOT" = false ]; then
  echo -e "${YELLOW}No AI assistants selected. Nothing to do.${NC}"
  exit 0
fi

STEP=1
TOTAL=0
[ "$SETUP_CLAUDE" = true ] && TOTAL=$((TOTAL + 1))
[ "$SETUP_GEMINI" = true ] && TOTAL=$((TOTAL + 1))
[ "$SETUP_CODEX" = true ] && TOTAL=$((TOTAL + 1))
[ "$SETUP_COPILOT" = true ] && TOTAL=$((TOTAL + 1))

if [ "$SETUP_CLAUDE" = true ]; then
  echo -e "${YELLOW}[$STEP/$TOTAL] Setting up Claude Code / Cursor...${NC}"
  setup_claude
  STEP=$((STEP + 1))
fi

if [ "$SETUP_GEMINI" = true ]; then
  echo -e "${YELLOW}[$STEP/$TOTAL] Setting up Gemini CLI...${NC}"
  setup_gemini
  STEP=$((STEP + 1))
fi

if [ "$SETUP_CODEX" = true ]; then
  echo -e "${YELLOW}[$STEP/$TOTAL] Setting up Codex (OpenAI)...${NC}"
  setup_codex
  STEP=$((STEP + 1))
fi

if [ "$SETUP_COPILOT" = true ]; then
  echo -e "${YELLOW}[$STEP/$TOTAL] Setting up GitHub Copilot...${NC}"
  setup_copilot
fi

echo ""
echo -e "${GREEN}✅ Successfully configured $SKILL_COUNT AI skills!${NC}"
echo ""
echo "Configured:"
[ "$SETUP_CLAUDE" = true ] && echo "  • Claude Code / Cursor: .claude/skills/ + .cursor/skills/ + CLAUDE.md"
[ "$SETUP_CODEX" = true ] && echo "  • Codex (OpenAI): .codex/skills/ + AGENTS.md (native)"
[ "$SETUP_GEMINI" = true ] && echo "  • Gemini CLI: .gemini/skills/ + GEMINI.md"
[ "$SETUP_COPILOT" = true ] && echo "  • GitHub Copilot: .github/copilot-instructions.md"
echo ""
echo -e "${BLUE}Note: Restart your AI assistant to load the skills.${NC}"
echo -e "${BLUE}      AGENTS.md is the source of truth — changes in skills/ apply via symlinks.${NC}"
echo -e "${BLUE}      Regenerate Auto-invoke tables: ./skills/skill-sync/assets/sync.sh${NC}"
