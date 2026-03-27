#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

GIT_DIR="${HOME}/develop/code/git"
CLAUDE_DIR="${HOME}/.claude"
AGENTS_DIR="${CLAUDE_DIR}/agents"
SKILLS_DIR="${CLAUDE_DIR}/skills"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
PATCHES_DIR="${CLAUDE_DIR}/patches"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Helpers ---

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; }
step()  { echo -e "\n${BOLD}==> $1${NC}"; }

usage() {
  cat <<EOF
${BOLD}Superpowers Agency Gstack - Modular Installer${NC}

Usage: ./setup.sh [OPTIONS]

Superpowers is always installed (required base).
Other components are optional add-ons:

OPTIONS:
  --agents     Install Agency Agents (50+ domain expert roles)
  --design     Install Design Skills (ui-ux-pro-max 7-skill suite)
  --gstack     Install Gstack Skills (security-audit, architecture-review)
  --all        Install all components
  --status     Show what's currently installed
  --help       Show this help

EXAMPLES:
  ./setup.sh                      # Base only (Superpowers + hook)
  ./setup.sh --agents             # + domain experts
  ./setup.sh --design             # + design intelligence
  ./setup.sh --gstack             # + security & architecture
  ./setup.sh --agents --design    # mix and match
  ./setup.sh --all                # everything
EOF
  exit 0
}

show_status() {
  echo -e "\n${BOLD}Current Installation Status${NC}\n"

  # Superpowers
  if claude plugin list 2>/dev/null | grep -q superpowers; then
    ok "Superpowers plugin installed"
  else
    warn "Superpowers plugin not found"
  fi

  # Patcher hook
  if [ -f "${HOOKS_DIR}/agency-superpowers-patcher.sh" ]; then
    ok "Patcher hook installed"
  elif [ -f "${HOOKS_DIR}/agency-superpowers.sh" ]; then
    warn "Legacy hook found (consider re-running setup.sh to upgrade to patcher)"
  else
    warn "Hook not installed"
  fi

  # Patches
  local patch_count=0
  if [ -d "${PATCHES_DIR}" ]; then
    patch_count=$(ls -1 "${PATCHES_DIR}"/*.patch.md 2>/dev/null | wc -l | tr -d ' ')
  fi
  if [ "$patch_count" -gt 0 ]; then
    ok "Patches installed (${patch_count} files)"
  else
    warn "No patches installed"
  fi

  # Agents
  if [ -d "${AGENTS_DIR}" ] && [ "$(ls -A "${AGENTS_DIR}" 2>/dev/null)" ]; then
    local count=$(ls -1 "${AGENTS_DIR}" | wc -l | tr -d ' ')
    ok "Agency Agents installed (${count} entries)"
  else
    warn "Agency Agents not installed"
  fi

  # Design Skills
  if [ -d "${SKILLS_DIR}/ui-ux-pro-max" ]; then
    local design_count=0
    for s in ui-ux-pro-max design brand banner-design ui-styling slides design-system; do
      [ -d "${SKILLS_DIR}/${s}" ] && ((design_count++))
    done
    ok "Design Skills installed (${design_count}/7)"
  else
    warn "Design Skills not installed"
  fi

  # Gstack
  local gstack_count=0
  [ -d "${SKILLS_DIR}/security-audit" ] && ((gstack_count++))
  [ -d "${SKILLS_DIR}/architecture-review" ] && ((gstack_count++))
  if [ $gstack_count -gt 0 ]; then
    ok "Gstack Skills installed (${gstack_count}/2)"
  else
    warn "Gstack Skills not installed"
  fi

  echo ""
  exit 0
}

# --- Component Installers ---

install_superpowers() {
  step "Installing Superpowers (required)"

  if claude plugin list 2>/dev/null | grep -q superpowers; then
    ok "Superpowers already installed"
  else
    info "Installing Superpowers plugin..."
    claude plugin install superpowers@claude-plugins-official
    ok "Superpowers installed"
  fi
}

install_agents() {
  step "Installing Agency Agents"

  local repo_dir="${GIT_DIR}/agency-agents"

  # Clone if not exists
  if [ ! -d "${repo_dir}" ]; then
    info "Cloning agency-agents..."
    mkdir -p "${GIT_DIR}"
    git clone --depth 1 https://github.com/msitarzewski/agency-agents.git "${repo_dir}"
  else
    ok "agency-agents repo already exists"
  fi

  mkdir -p "${AGENTS_DIR}"

  # Symlink non-engineering directories
  for dir in academic examples marketing paid-media product project-management sales specialized support game-development; do
    if [ -d "${repo_dir}/${dir}" ]; then
      ln -sfn "${repo_dir}/${dir}" "${AGENTS_DIR}/${dir}"
      info "Linked ${dir}/"
    fi
  done

  # Design: only keep inclusive-visuals-specialist (others covered by design skills)
  if [ -f "${repo_dir}/design/design-inclusive-visuals-specialist.md" ]; then
    ln -sf "${repo_dir}/design/design-inclusive-visuals-specialist.md" "${AGENTS_DIR}/design-inclusive-visuals-specialist.md"
    info "Linked design-inclusive-visuals-specialist.md"
  fi

  # Single engineering role
  if [ -f "${repo_dir}/engineering/engineering-incident-response-commander.md" ]; then
    ln -sf "${repo_dir}/engineering/engineering-incident-response-commander.md" "${AGENTS_DIR}/engineering-incident-response-commander.md"
    info "Linked engineering-incident-response-commander.md"
  fi

  ok "Agency Agents installed"
}

install_design() {
  step "Installing Design Skills (ui-ux-pro-max suite)"

  local repo_dir="${GIT_DIR}/ui-ux-pro-max-skill"

  # Clone if not exists
  if [ ! -d "${repo_dir}" ]; then
    info "Cloning ui-ux-pro-max-skill..."
    mkdir -p "${GIT_DIR}"
    git clone --depth 1 https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.git "${repo_dir}"
  else
    ok "ui-ux-pro-max-skill repo already exists"
  fi

  mkdir -p "${SKILLS_DIR}"

  # Check source skills exist
  local source_skills="${repo_dir}/.claude/skills"
  if [ ! -d "${source_skills}" ]; then
    err "Skills directory not found at ${source_skills}"
    err "The repo may need updating: cd ${repo_dir} && git pull"
    return 1
  fi

  # Symlink all 7 skills
  for skill in ui-ux-pro-max design brand banner-design ui-styling slides design-system; do
    if [ -d "${source_skills}/${skill}" ]; then
      ln -sfn "${source_skills}/${skill}" "${SKILLS_DIR}/${skill}"
      info "Linked ${skill}/"
    else
      warn "Skill ${skill} not found in source repo"
    fi
  done

  ok "Design Skills installed (7 skills)"
}

install_gstack() {
  step "Installing Gstack Skills"

  local repo_dir="${GIT_DIR}/gstack"

  # Clone if not exists
  if [ ! -d "${repo_dir}" ]; then
    info "Cloning gstack..."
    mkdir -p "${GIT_DIR}"
    git clone --depth 1 https://github.com/garrytan/gstack.git "${repo_dir}"
  else
    ok "gstack repo already exists"
  fi

  mkdir -p "${SKILLS_DIR}"

  # Install security-audit (from gstack /cso)
  if [ -d "${repo_dir}/cso" ]; then
    mkdir -p "${SKILLS_DIR}/security-audit"
    cp "${repo_dir}/cso/SKILL.md" "${SKILLS_DIR}/security-audit/SKILL.md"
    info "Installed security-audit"
  else
    warn "gstack /cso not found"
  fi

  # Install architecture-review (from gstack /plan-eng-review)
  if [ -d "${repo_dir}/plan-eng-review" ]; then
    mkdir -p "${SKILLS_DIR}/architecture-review"
    cp "${repo_dir}/plan-eng-review/SKILL.md" "${SKILLS_DIR}/architecture-review/SKILL.md"
    info "Installed architecture-review"
  else
    warn "gstack /plan-eng-review not found"
  fi

  ok "Gstack Skills installed"
}

# --- Patcher + Patches Installer ---

install_hook() {
  step "Installing patcher hook + patches"

  mkdir -p "${HOOKS_DIR}" "${PATCHES_DIR}"

  # Remove legacy hook if exists
  if [ -f "${HOOKS_DIR}/agency-superpowers.sh" ]; then
    rm "${HOOKS_DIR}/agency-superpowers.sh"
    info "Removed legacy hook (agency-superpowers.sh)"
  fi

  # Copy patcher script
  cp "${SCRIPT_DIR}/patcher.sh" "${HOOKS_DIR}/agency-superpowers-patcher.sh"
  chmod +x "${HOOKS_DIR}/agency-superpowers-patcher.sh"
  info "Installed patcher hook"

  # Copy patch files
  local patch_count=0
  for patch_file in "${SCRIPT_DIR}/patches"/*.patch.md; do
    [ -f "$patch_file" ] || continue
    cp "$patch_file" "${PATCHES_DIR}/"
    ((patch_count++))
  done
  info "Installed ${patch_count} patch files"

  # Run patcher immediately to apply patches
  bash "${HOOKS_DIR}/agency-superpowers-patcher.sh" 2>/dev/null || true

  ok "Patcher hook + patches installed (zero token consumption per session)"
}

install_settings() {
  step "Registering patcher hook in settings.json"

  local settings_file="${CLAUDE_DIR}/settings.json"

  # Check if patcher already registered
  if [ -f "${settings_file}" ] && grep -q "agency-superpowers-patcher.sh" "${settings_file}" 2>/dev/null; then
    ok "Patcher hook already registered in settings.json"
    return
  fi

  # Migrate from legacy hook if present
  if [ -f "${settings_file}" ] && grep -q "agency-superpowers.sh" "${settings_file}" 2>/dev/null; then
    sed -i '' 's/agency-superpowers\.sh/agency-superpowers-patcher.sh/g' "${settings_file}"
    ok "Migrated settings.json from legacy hook to patcher"
    return
  fi

  # If settings.json doesn't exist, create minimal one
  if [ ! -f "${settings_file}" ]; then
    cat > "${settings_file}" << 'SETTINGSEOF'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.claude/hooks/agency-superpowers-patcher.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
SETTINGSEOF
    ok "Created settings.json with patcher hook"
  else
    warn "settings.json exists but patcher not found — please add manually:"
    echo ""
    echo '  "hooks": {'
    echo '    "SessionStart": [{'
    echo '      "hooks": [{'
    echo '        "type": "command",'
    echo '        "command": "bash $HOME/.claude/hooks/agency-superpowers-patcher.sh",'
    echo '        "timeout": 5'
    echo '      }]'
    echo '    }]'
    echo '  }'
    echo ""
  fi
}

# --- Main ---

INSTALL_AGENTS=false
INSTALL_DESIGN=false
INSTALL_GSTACK=false

# Parse args
if [ $# -eq 0 ]; then
  # Base only
  true
fi

for arg in "$@"; do
  case $arg in
    --agents)  INSTALL_AGENTS=true ;;
    --design)  INSTALL_DESIGN=true ;;
    --gstack)  INSTALL_GSTACK=true ;;
    --all)     INSTALL_AGENTS=true; INSTALL_DESIGN=true; INSTALL_GSTACK=true ;;
    --status)  show_status ;;
    --help|-h) usage ;;
    *)         err "Unknown option: $arg"; usage ;;
  esac
done

echo -e "\n${BOLD}Superpowers Agency Gstack Installer${NC}\n"

# Always install superpowers
install_superpowers

# Optional components
$INSTALL_AGENTS && install_agents
$INSTALL_DESIGN && install_design
$INSTALL_GSTACK && install_gstack

# Always generate hook (adapts to what's installed)
install_hook
install_settings

# Summary
step "Installation complete"
echo ""
info "Installed components:"
ok "Superpowers (required)"
$INSTALL_AGENTS && ok "Agency Agents"
$INSTALL_DESIGN && ok "Design Skills (ui-ux-pro-max suite)"
$INSTALL_GSTACK && ok "Gstack Skills (security-audit, architecture-review)"
echo ""
info "Restart Claude Code to activate."
echo ""
