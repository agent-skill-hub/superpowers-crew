<!-- ANCHOR: ### Step 2: Execute Tasks -->
<!-- PATCH:executing-plans v1 -->

### Crew Integration: Role-Based Execution

When executing tasks from the plan, check if each task has a `**Role:**` field assigned during planning:

1. **If the task has a Role with a matching `subagent_type`** (from `~/.claude/agents/`): bring that role's domain expertise to the execution — consider the task through that role's lens.
2. **If the task involves design work**: use the relevant design skill BEFORE writing code (see skill mapping in the plan's Role assignment table).
3. **If no Role is assigned**: infer the appropriate role from the task description.

In all cases, apply the role's domain perspective:

> Think as a [Role]. Consider: What would this role prioritize? What risks would they flag? What quality standards would they enforce?
