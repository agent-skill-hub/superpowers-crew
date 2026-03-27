<!-- ANCHOR: ## Self-Review -->
<!-- PATCH:writing-plans v1 -->

### Crew Integration: Role Assignment & Skill Mapping

After writing the plan and BEFORE dispatching the plan-document-reviewer or handing off to execution:

1. **Assign a domain expert role to each task via `**Role:**` field**
2. **For architecture-heavy plans (8+ files), recommend running `/architecture-review`**

**Role assignment guide:**

| Task type | Assign role | Skill integration |
|---|---|---|
| Visual layout, component design | UI Designer | `ui-ux-pro-max` (search.py --domain style) |
| User flow, interaction design | UX Architect | `ui-ux-pro-max` (search.py --domain ux) |
| Color palette, typography | UI Designer | `ui-ux-pro-max` (search.py --domain color/typography) |
| Charts, data visualization | UI Designer | `ui-ux-pro-max` (search.py --domain chart) |
| shadcn/ui components, Tailwind | UI Developer | `ui-styling` |
| Design tokens, CSS variables | UI Developer | `design-system` |
| Logo, icon, CIP mockups | Visual Designer | `design` |
| Banner, ad creative, social images | Visual Designer | `banner-design` |
| Brand voice, messaging, style guide | Brand Strategist | `brand` |
| Slides, presentations | Content Designer | `slides` |
| Copywriting, headlines, CTAs | Conversion Copywriter | |
| Analytics, UTM, tracking | Growth Analyst | |
| SEO, meta tags | SEO Strategist | |
| Security-sensitive changes | Security Engineer | recommend `/security-audit` after implementation |
| Architecture changes (8+ files) | Architect | recommend `/architecture-review` before implementation |
| API integration, backend | Backend Engineer | |
| General implementation | Senior Software Engineer | |
