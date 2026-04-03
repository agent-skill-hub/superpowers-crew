<!-- ANCHOR: **Core principle:** -->
<!-- PATCH:subagent-driven-development v1 -->

### Crew Integration: Role-Based Subagent Dispatch

When dispatching implementer subagents, use the `**Role:**` field from the plan to select the subagent type:

1. **Search the agent archive** for a matching specialist:
   ```bash
   python ~/.claude/skills/skill-router/scripts/search.py "Role keywords"
   ```
   If matched, Read the agent .md and inject its full definition into the `general-purpose` subagent prompt as role context.
2. **If no match found**: use `general-purpose` with role framing in the prompt.

In all cases, prepend in the implementer prompt:

> "You are a [Role]. Bring your domain expertise to this task. [Role-specific lens: e.g., 'Think about compliance impact', 'Consider failure modes', 'Optimize for observability'.]"

If the plan has no role assigned, infer the appropriate role from the task description before dispatching.

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
| shadcn/ui, Tailwind styling | `ui-styling` | Read `~/.claude/skills/ui-styling/SKILL.md` |
| Design tokens, CSS vars | `design-system` | Read `~/.claude/skills/design-system/SKILL.md` |
| Logo generation | `design` | Read `~/.claude/skills/design/SKILL.md` section Logo |
| Icon design | `design` | Read `~/.claude/skills/design/SKILL.md` section Icon |
| CIP / brand mockups | `design` | Read `~/.claude/skills/design/SKILL.md` section CIP |
| Social media images | `design` | Read `~/.claude/skills/design/SKILL.md` section Social Photos |
| Banner / ad creative | `banner-design` | Read `~/.claude/skills/banner-design/SKILL.md` |
| Brand voice, messaging | `brand` | Read `~/.claude/skills/brand/SKILL.md` |
| Presentation slides | `slides` | Read `~/.claude/skills/slides/SKILL.md` |

The search output and skill guidance provide data-driven recommendations. Use these as constraints when implementing, not just as suggestions.
