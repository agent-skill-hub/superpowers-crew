<!-- ANCHOR: 1. **Explore project context** -->
<!-- PATCH:brainstorming v1 -->

### Crew Integration: Domain Experts & Design Skills

**BEFORE asking clarifying questions (after exploring project context), you MUST:**

#### A. Design Intelligence (if project involves UI/UX)

If the project involves UI/UX (website, app, landing page, dashboard, component design), first run the design system generator to ground the discussion in data-driven recommendations:

```
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system
```

Use the output (style, colors, typography, anti-patterns) as input to the brainstorming discussion.

If the project involves branding (new brand, rebranding, branded content), read `~/.claude/skills/brand/SKILL.md` for brand voice and visual identity framework.

#### B. Domain Expert Consultation

Identify which domain expert roles are relevant to this project. Search the agent archive for matching specialists, then dispatch them for consultation.

**How to consult domain experts:**

1. Search the archive for relevant experts:
```bash
python ~/.claude/skills/skill-router/scripts/search.py "project-relevant keywords" --top 5
```

2. For each matched agent, Read its .md file to get the full role definition
3. Dispatch a `general-purpose` subagent with the agent definition as role context:

> "You are a [Role from agent .md]. The user wants to build: [brief description].
> Provide your top 3-5 observations, risks, and recommendations from your domain perspective. Be specific and opinionated. 2-3 sentences each."

4. Collect responses, then synthesize into your clarifying questions and approach proposals. Attribute insights where relevant.

**Note:** If skill-router returns no matches, skip expert consultation — `general-purpose` without domain framing adds little value.
