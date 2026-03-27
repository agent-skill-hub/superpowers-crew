<!-- ANCHOR: ## When To Apply -->
<!-- PATCH:verification-before-completion v1 -->

### Crew Integration: Pre-Delivery Skill Checks

Before claiming work is done, recommend relevant skills based on change scope:

- Security-sensitive code -> `/security-audit`
- PR ready for merge -> `/requesting-code-review` (superpowers subagent)
- Bug fix -> `/systematic-debugging` methodology was hopefully already used
- Architecture change -> `/architecture-review` should have been done at plan stage
- UI/UX changes -> run `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "accessibility animation z-index loading" --domain ux` as pre-delivery UX validation
- Brand/visual assets -> verify against `brand` skill guidelines and brand-guidelines.md if exists
- Design tokens -> validate token hierarchy (primitive->semantic->component) per `design-system` skill
