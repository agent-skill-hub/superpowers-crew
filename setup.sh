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

  # Hook
  if [ -f "${HOOKS_DIR}/agency-superpowers.sh" ]; then
    ok "Hook installed"
  else
    warn "Hook not installed"
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

# --- Hook Generator (detection-based) ---

install_hook() {
  step "Generating hook"

  mkdir -p "${HOOKS_DIR}"

  cat > "${HOOKS_DIR}/agency-superpowers.sh" << 'HOOKSCRIPT'
#!/usr/bin/env bash
# Auto-detecting hook: outputs instructions based on what's installed

AGENTS_DIR="$HOME/.claude/agents"
SKILLS_DIR="$HOME/.claude/skills"

echo '<AGENCY_SUPERPOWERS>'
echo ''
echo '## Superpowers Integration Layer'
echo ''
echo 'These instructions SUPPLEMENT the superpowers skills. They apply on top of brainstorming, writing-plans, and subagent-driven-development. Follow them in addition to the skill'"'"'s own process.'

# --- Design Skills Section (if installed) ---
if [ -d "$SKILLS_DIR/ui-ux-pro-max" ]; then
cat << 'DESIGN_SECTION'

### Design Skills Reference

Seven design skills are available at `~/.claude/skills/`. Subagents can use them via Bash (scripts) or by reading SKILL.md for workflow guidance.

| Skill | What it does | When to use |
|---|---|---|
| `ui-ux-pro-max` | Design intelligence: 67 styles, 161 palettes, 57 fonts, 99 UX rules, search.py engine | Any UI/UX work — always start here |
| `design` | Logo (55 styles, Gemini), CIP mockups, icon design, social photos | Brand visual asset creation |
| `brand` | Brand voice, visual identity, messaging frameworks, consistency audit | Branded content, tone of voice |
| `banner-design` | 22 styles of banners for social/ads/web/print | Marketing visuals, ad creatives |
| `ui-styling` | shadcn/ui + Tailwind CSS + dark mode + a11y components | Code-level UI implementation |
| `design-system` | Three-layer tokens (primitive→semantic→component), CSS variables | Design token architecture |
| `slides` | HTML presentations with Chart.js, copywriting formulas | Slide decks, data presentations |

**Dependency chain:** `brand` + `design-system` → `ui-styling` → `design` → `banner-design` / `slides`
DESIGN_SECTION
fi

# --- Brainstorming Section ---
cat << 'BRAINSTORM_SECTION'

### When using `brainstorming`

After exploring project context and BEFORE asking clarifying questions:
BRAINSTORM_SECTION

if [ -d "$SKILLS_DIR/ui-ux-pro-max" ]; then
cat << 'BRAINSTORM_DESIGN'

1. **If the project involves UI/UX** (website, app, landing page, dashboard, component design), first run the design system generator to ground the discussion in data-driven recommendations:
   ```
   python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system
   ```
   Use the output (style, colors, typography, anti-patterns) as input to the brainstorming discussion.

2. **If the project involves branding** (new brand, rebranding, branded content), read `~/.claude/skills/brand/SKILL.md` for brand voice and visual identity framework.
BRAINSTORM_DESIGN
fi

if [ -L "$AGENTS_DIR/marketing" ] || [ -L "$AGENTS_DIR/product" ]; then
cat << 'BRAINSTORM_AGENTS'

Identify which domain expert roles are relevant to this project. Then dispatch a domain expert consultation subagent for each relevant role, asking them to contribute their perspective to the design. Incorporate their input into the clarifying questions and approach proposals.

**Role selection guide:**

| Project type | Relevant roles |
|---|---|
| Ad / marketing landing page | Ad Creative Strategist, Conversion Copywriter, UX Architect, Paid Social Strategist |
| Consumer product / app | Product Designer, UX Architect, Growth Hacker |
| B2B SaaS | Product Manager, Sales Engineer, UX Architect |
| Game / entertainment | Game Designer, Creative Director, Narrative Designer |
| Internal tool / dashboard | UX Architect, Data Analyst |
| API / developer tool | Developer Advocate, Technical Writer |
| E-commerce | Conversion Rate Optimizer, Brand Strategist, UX Architect |
| Payment system / fintech | Compliance Auditor, Security Engineer, Backend Architect |
| Microservices / infrastructure | SRE, Backend Architect, DevOps Automator |

**How to consult a domain expert:**
Dispatch a subagent for each relevant role. If the role name matches an available `subagent_type` (from `.claude/agents/`), use that subagent_type to load the full agent definition. Otherwise, fall back to `subagent_type=general-purpose` with role framing.

> "You are a [Role]. The user wants to build: [brief description].
> Provide your top 3-5 observations, risks, and recommendations from your domain perspective. Be specific and opinionated. 2-3 sentences each."

Collect responses, then synthesize into your clarifying questions and approach proposals. Attribute insights: "从合规角度..." / "安全工程师建议..."
BRAINSTORM_AGENTS
fi

# --- Writing Plans Section ---
cat << 'PLANS_SECTION'

### When using `writing-plans`

After writing the plan and BEFORE dispatching the plan-document-reviewer:
1. Assign a domain expert role to each task via `**Role:**` field
2. For architecture-heavy plans, recommend running `/architecture-review`

**Role assignment examples:**

| Task type | Assign role | Skill integration |
|---|---|---|
PLANS_SECTION

if [ -d "$SKILLS_DIR/ui-ux-pro-max" ]; then
cat << 'PLANS_DESIGN'
| Visual layout, component design | UI Designer | → `ui-ux-pro-max` (search.py --domain style) |
| User flow, interaction design | UX Architect | → `ui-ux-pro-max` (search.py --domain ux) |
| Color palette, typography | UI Designer | → `ui-ux-pro-max` (search.py --domain color/typography) |
| Charts, data visualization | UI Designer | → `ui-ux-pro-max` (search.py --domain chart) |
| shadcn/ui components, Tailwind | UI Developer | → `ui-styling` |
| Design tokens, CSS variables | UI Developer | → `design-system` |
| Logo, icon, CIP mockups | Visual Designer | → `design` |
| Banner, ad creative, social images | Visual Designer | → `banner-design` |
| Brand voice, messaging, style guide | Brand Strategist | → `brand` |
| Slides, presentations | Content Designer | → `slides` |
PLANS_DESIGN
fi

cat << 'PLANS_COMMON'
| Copywriting, headlines, CTAs | Conversion Copywriter | |
| Analytics, UTM, tracking | Growth Analyst | |
| SEO, meta tags | SEO Strategist | |
| Security-sensitive changes | | → recommend `/security-audit` after implementation |
| Architecture changes (8+ files) | | → recommend `/architecture-review` before implementation |
| API integration, backend | Backend Engineer | |
| General implementation | Senior Software Engineer | |
PLANS_COMMON

# --- Subagent-Driven Development Section ---
cat << 'SUBAGENT_SECTION'

### When using `subagent-driven-development`

When dispatching implementer subagents, use the `**Role:**` field from the plan to select the subagent type:
SUBAGENT_SECTION

if [ -L "$AGENTS_DIR/marketing" ] || [ -L "$AGENTS_DIR/product" ]; then
cat << 'SUBAGENT_AGENTS'

1. **If the Role matches an available `subagent_type`** (from `.claude/agents/`): use that `subagent_type` instead of `general-purpose`. This loads the full agent definition (identity, rules, workflow, output format), overriding the template's default `general-purpose`.
2. **If no matching `subagent_type` exists**: fall back to `general-purpose` and prepend role framing in the prompt.
SUBAGENT_AGENTS
fi

cat << 'SUBAGENT_COMMON'

In all cases, prepend in the implementer prompt:

> "You are a [Role]. Bring your domain expertise to this task. [Role-specific lens: e.g., 'Think about compliance impact', 'Consider failure modes', 'Optimize for observability'.]"

If the plan has no role assigned, infer the appropriate role from the task description before dispatching.
SUBAGENT_COMMON

if [ -d "$SKILLS_DIR/ui-ux-pro-max" ]; then
cat << 'SUBAGENT_DESIGN'

**Design skill integration for subagents:**

When a task involves design work, the implementer subagent MUST use the relevant skill BEFORE writing code. Match by task type:

| Task involves | Skill to use | How |
|---|---|---|
| New project / new page | `ui-ux-pro-max` | `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<keywords>" --design-system -p "<project>"` |
| Style / visual design | `ui-ux-pro-max` | `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<keywords>" --domain style` |
| Color palette | `ui-ux-pro-max` | `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<keywords>" --domain color` |
| Typography / fonts | `ui-ux-pro-max` | `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<keywords>" --domain typography` |
| Charts / data viz | `ui-ux-pro-max` | `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<keywords>" --domain chart` |
| UX patterns / a11y | `ui-ux-pro-max` | `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<keywords>" --domain ux` |
| Stack best practices | `ui-ux-pro-max` | `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<keywords>" --stack <stack>` |
| shadcn/ui, Tailwind styling | `ui-styling` | Read `~/.claude/skills/ui-styling/SKILL.md` for component patterns and Tailwind conventions |
| Design tokens, CSS vars | `design-system` | Read `~/.claude/skills/design-system/SKILL.md`; run token generation scripts |
| Logo generation | `design` | Read `~/.claude/skills/design/SKILL.md` § Logo; run `scripts/logo/generate.py` |
| Icon design | `design` | Read `~/.claude/skills/design/SKILL.md` § Icon; run `scripts/icon/generate.py` |
| CIP / brand mockups | `design` | Read `~/.claude/skills/design/SKILL.md` § CIP; run `scripts/cip/generate.py` |
| Social media images | `design` | Read `~/.claude/skills/design/SKILL.md` § Social Photos; HTML→screenshot workflow |
| Banner / ad creative | `banner-design` | Read `~/.claude/skills/banner-design/SKILL.md`; follows art direction → HTML → export pipeline |
| Brand voice, messaging | `brand` | Read `~/.claude/skills/brand/SKILL.md`; check `docs/brand-guidelines.md` if exists |
| Presentation slides | `slides` | Read `~/.claude/skills/slides/SKILL.md`; use Chart.js for data slides |

The search output and skill guidance provide data-driven recommendations. Use these as constraints when implementing, not just as suggestions.
SUBAGENT_DESIGN
fi

# --- Completing Implementation Section ---
cat << 'COMPLETE_SECTION'

### When completing implementation

Before claiming work is done, recommend relevant skills based on change scope:
- Security-sensitive code → `/security-audit`
- PR ready for merge → `/requesting-code-review` (superpowers subagent)
- Bug fix → `/systematic-debugging` methodology was hopefully already used
- Architecture change → `/architecture-review` should have been done at plan stage
COMPLETE_SECTION

if [ -d "$SKILLS_DIR/ui-ux-pro-max" ]; then
cat << 'COMPLETE_DESIGN'
- UI/UX changes → run `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "accessibility animation z-index loading" --domain ux` as pre-delivery UX validation
- Brand/visual assets → verify against `brand` skill guidelines and brand-guidelines.md if exists
- Design tokens → validate token hierarchy (primitive→semantic→component) per `design-system` skill
COMPLETE_DESIGN
fi

echo ''
echo '</AGENCY_SUPERPOWERS>'
HOOKSCRIPT

  chmod +x "${HOOKS_DIR}/agency-superpowers.sh"
  ok "Hook generated (auto-detects installed components)"
}

install_settings() {
  step "Registering hook in settings.json"

  local settings_file="${CLAUDE_DIR}/settings.json"

  # Check if hook already registered
  if [ -f "${settings_file}" ] && grep -q "agency-superpowers.sh" "${settings_file}" 2>/dev/null; then
    ok "Hook already registered in settings.json"
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
            "command": "bash $HOME/.claude/hooks/agency-superpowers.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
SETTINGSEOF
    ok "Created settings.json with hook"
  else
    warn "settings.json exists but hook not found — please add manually:"
    echo ""
    echo '  "hooks": {'
    echo '    "SessionStart": [{'
    echo '      "hooks": [{'
    echo '        "type": "command",'
    echo '        "command": "bash $HOME/.claude/hooks/agency-superpowers.sh",'
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
