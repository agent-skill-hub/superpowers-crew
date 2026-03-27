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

Collect responses, then synthesize into your clarifying questions and approach proposals. Attribute insights where relevant.
