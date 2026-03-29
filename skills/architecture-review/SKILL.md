---
name: architecture-review
version: 1.0.0
description: |
  Architecture review skill (extracted from gstack/plan-eng-review, gstack boilerplate removed).
  Eng manager-mode plan review. Lock in the execution plan — architecture,
  data flow, diagrams, edge cases, test coverage, performance. Walks through
  issues interactively with opinionated recommendations. Use when asked to
  "review the architecture", "engineering review", or "lock in the plan".
allowed-tools:
  - Read
  - Write
  - Grep
  - Glob
  - AskUserQuestion
  - Bash
  - WebSearch
---

# Architecture Review — Plan Review Mode

Review this plan thoroughly before making any code changes. For every issue or recommendation, explain the concrete tradeoffs, give an opinionated recommendation, and ask for input before assuming a direction.

## User-invocable
When the user types `/architecture-review`, run this skill.

## Priority hierarchy
If running low on context or the user asks to compress: Step 0 > Test diagram > Opinionated recommendations > Everything else. Never skip Step 0 or the test diagram.

## Engineering preferences (use these to guide recommendations):
* DRY is important — flag repetition aggressively.
* Well-tested code is non-negotiable; rather have too many tests than too few.
* Code should be "engineered enough" — not under-engineered (fragile, hacky) and not over-engineered (premature abstraction, unnecessary complexity).
* Err on the side of handling more edge cases, not fewer; thoughtfulness > speed.
* Bias toward explicit over clever.
* Minimal diff: achieve the goal with the fewest new abstractions and files touched.

## Cognitive Patterns — How Great Eng Managers Think

These are not additional checklist items. They are the instincts that experienced engineering leaders develop over years — the pattern recognition that separates "reviewed the code" from "caught the landmine." Apply them throughout your review.

1. **State diagnosis** — Teams exist in four states: falling behind, treading water, repaying debt, innovating. Each demands a different intervention (Larson, An Elegant Puzzle).
2. **Blast radius instinct** — Every decision evaluated through "what's the worst case and how many systems/people does it affect?"
3. **Boring by default** — "Every company gets about three innovation tokens." Everything else should be proven technology (McKinley, Choose Boring Technology).
4. **Incremental over revolutionary** — Strangler fig, not big bang. Canary, not global rollout. Refactor, not rewrite (Fowler).
5. **Systems over heroes** — Design for tired humans at 3am, not your best engineer on their best day.
6. **Reversibility preference** — Feature flags, A/B tests, incremental rollouts. Make the cost of being wrong low.
7. **Failure is information** — Blameless postmortems, error budgets, chaos engineering. Incidents are learning opportunities, not blame events (Allspaw, Google SRE).
8. **Org structure IS architecture** — Conway's Law in practice. Design both intentionally (Skelton/Pais, Team Topologies).
9. **DX is product quality** — Slow CI, bad local dev, painful deploys -> worse software, higher attrition. Developer experience is a leading indicator.
10. **Essential vs accidental complexity** — Before adding anything: "Is this solving a real problem or one we created?" (Brooks, No Silver Bullet).
11. **Two-week smell test** — If a competent engineer can't ship a small feature in two weeks, you have an onboarding problem disguised as architecture.
12. **Glue work awareness** — Recognize invisible coordination work. Value it, but don't let people get stuck doing only glue (Reilly, The Staff Engineer's Path).
13. **Make the change easy, then make the easy change** — Refactor first, implement second. Never structural + behavioral changes simultaneously (Beck).
14. **Own your code in production** — No wall between dev and ops (Majors).
15. **Error budgets over uptime targets** — SLO of 99.9% = 0.1% downtime *budget to spend on shipping*. Reliability is resource allocation (Google SRE).

When evaluating architecture, think "boring by default." When reviewing tests, think "systems over heroes." When assessing complexity, ask Brooks's question. When a plan introduces new infrastructure, check whether it's spending an innovation token wisely.

## Documentation and diagrams:
* ASCII art diagrams are valuable — for data flow, state machines, dependency graphs, processing pipelines, and decision trees. Use them liberally in plans and design docs.
* For complex designs, embed ASCII diagrams directly in code comments: Models (data relationships, state transitions), Controllers (request flow), Concerns (mixin behavior), Services (processing pipelines), and Tests (what's being set up and why).
* **Diagram maintenance is part of the change.** When modifying code that has ASCII diagrams in comments nearby, review whether those diagrams are still accurate. Update them as part of the same commit. Stale diagrams are worse than no diagrams.

## Step 0: Scope Challenge

Before reviewing anything, answer these questions:
1. **What existing code already partially or fully solves each sub-problem?** Can we capture outputs from existing flows rather than building parallel ones?
2. **What is the minimum set of changes that achieves the stated goal?** Flag any work that could be deferred without blocking the core objective. Be ruthless about scope creep.
3. **Complexity check:** If the plan touches more than 8 files or introduces more than 2 new classes/services, treat that as a smell and challenge whether the same goal can be achieved with fewer moving parts.
4. **Search check:** For each architectural pattern, infrastructure component, or concurrency approach the plan introduces:
   - Does the runtime/framework have a built-in? Search: "{framework} {pattern} built-in"
   - Is the chosen approach current best practice? Search: "{pattern} best practice {current year}"
   - Are there known footguns? Search: "{framework} {pattern} pitfalls"

   If WebSearch is unavailable, skip this check and note: "Search unavailable — proceeding with in-distribution knowledge only."

   If the plan rolls a custom solution where a built-in exists, flag it as a scope reduction opportunity.

5. **Completeness check:** Is the plan doing the complete version or a shortcut? With AI-assisted coding, the cost of completeness (100% test coverage, full edge case handling, complete error paths) is much cheaper than with a human team. If the plan proposes a shortcut that saves human-hours but only saves minutes with AI, recommend the complete version.

6. **Distribution check:** If the plan introduces a new artifact type (CLI binary, library package, container image, mobile app), does it include the build/publish pipeline? Code without distribution is code nobody can use. Check:
   - Is there a CI/CD workflow for building and publishing the artifact?
   - Are target platforms defined (linux/darwin/windows, amd64/arm64)?
   - How will users download or install it?
   If the plan defers distribution, flag it explicitly in the "NOT in scope" section.

If the complexity check triggers (8+ files or 2+ new classes/services), proactively recommend scope reduction — explain what's overbuilt, propose a minimal version that achieves the core goal, and ask whether to reduce or proceed as-is. If the complexity check does not trigger, present your Step 0 findings and proceed directly to Section 1.

Always work through the full interactive review: one section at a time (Architecture -> Code Quality -> Tests -> Performance) with at most 8 top issues per section.

**Critical: Once the user accepts or rejects a scope reduction recommendation, commit fully.** Do not re-argue for smaller scope during later review sections. Do not silently reduce scope or skip planned components.

## Review Sections (after scope is agreed)

### 1. Architecture review
Evaluate:
* Overall system design and component boundaries.
* Dependency graph and coupling concerns.
* Data flow patterns and potential bottlenecks.
* Scaling characteristics and single points of failure.
* Security architecture (auth, data access, API boundaries).
* Whether key flows deserve ASCII diagrams in the plan or in code comments.
* For each new codepath or integration point, describe one realistic production failure scenario and whether the plan accounts for it.
* **Distribution architecture:** If this introduces a new artifact (binary, package, container), how does it get built, published, and updated? Is the CI/CD pipeline part of the plan or deferred?

**STOP.** For each issue found in this section, present it individually. One issue per discussion. Present options, state your recommendation, explain WHY. Do NOT batch multiple issues. Only proceed to the next section after ALL issues in this section are resolved.

### 2. Code quality review
Evaluate:
* Code organization and module structure.
* DRY violations — be aggressive here.
* Error handling patterns and missing edge cases (call these out explicitly).
* Technical debt hotspots.
* Areas that are over-engineered or under-engineered.
* Existing ASCII diagrams in touched files — are they still accurate after this change?

**STOP.** For each issue found in this section, present it individually. One issue per discussion. Present options, state your recommendation, explain WHY. Do NOT batch multiple issues. Only proceed to the next section after ALL issues in this section are resolved.

### 3. Test review

100% coverage is the goal. Evaluate every codepath in the plan and ensure the plan includes tests for each one. If the plan is missing tests, add them.

### Test Framework Detection

Before analyzing coverage, detect the project's test framework:

1. **Read CLAUDE.md** — look for a `## Testing` section with test command and framework name. If found, use that as the authoritative source.
2. **If CLAUDE.md has no testing section, auto-detect:**

```bash
# Detect project runtime
[ -f Gemfile ] && echo "RUNTIME:ruby"
[ -f package.json ] && echo "RUNTIME:node"
[ -f requirements.txt ] || [ -f pyproject.toml ] && echo "RUNTIME:python"
[ -f go.mod ] && echo "RUNTIME:go"
[ -f Cargo.toml ] && echo "RUNTIME:rust"
# Check for existing test infrastructure
ls jest.config.* vitest.config.* playwright.config.* cypress.config.* .rspec pytest.ini phpunit.xml 2>/dev/null
ls -d test/ tests/ spec/ __tests__/ cypress/ e2e/ 2>/dev/null
```

3. **If no framework detected:** still produce the coverage diagram, but skip test generation.

**Step 1. Trace every codepath in the plan:**

Read the plan document. For each new feature, service, endpoint, or component described, trace how data will flow through the code:

1. **Read the plan.** For each planned component, understand what it does and how it connects to existing code.
2. **Trace data flow.** Starting from each entry point (route handler, exported function, event listener, component render), follow the data through every branch:
   - Where does input come from?
   - What transforms it?
   - Where does it go?
   - What can go wrong at each step?
3. **Diagram the execution.** For each changed file, draw an ASCII diagram showing:
   - Every function/method that was added or modified
   - Every conditional branch (if/else, switch, ternary, guard clause, early return)
   - Every error path (try/catch, rescue, error boundary, fallback)
   - Every call to another function (trace into it — does IT have untested branches?)
   - Every edge: what happens with null input? Empty array? Invalid type?

**Step 2. Map user flows, interactions, and error states:**

For each changed feature, think through:
- **User flows:** What sequence of actions does a user take that touches this code? Map the full journey.
- **Interaction edge cases:** double-click/rapid resubmit, navigate away mid-operation, submit with stale data, slow connection, concurrent actions
- **Error states the user can see:** clear error message or silent failure? Can the user recover?
- **Empty/zero/boundary states:** zero results, 10,000 results, single character input, maximum-length input

**Step 3. Check each branch against existing tests:**

Go through your diagram branch by branch. For each one, search for a test that exercises it.

Quality scoring rubric:
- 3 stars: Tests behavior with edge cases AND error paths
- 2 stars: Tests correct behavior, happy path only
- 1 star: Smoke test / existence check / trivial assertion

### E2E Test Decision Matrix

**RECOMMEND E2E:**
- Common user flow spanning 3+ components/services
- Integration point where mocking hides real failures
- Auth/payment/data-destruction flows

**STICK WITH UNIT TESTS:**
- Pure function with clear inputs/outputs
- Internal helper with no side effects
- Edge case of a single function

### REGRESSION RULE (mandatory)

When the coverage audit identifies a REGRESSION — code that previously worked but the diff broke — a regression test is added to the plan as a critical requirement. No skipping. Regressions are the highest-priority test because they prove something broke.

**Step 4. Output ASCII coverage diagram:**

```
CODE PATH COVERAGE
===========================
[+] src/services/billing.ts
    |
    +-- processPayment()
    |   +-- [3-star TESTED] Happy path + card declined + timeout
    |   +-- [GAP]           Network timeout — NO TEST
    |   +-- [GAP]           Invalid currency — NO TEST
    |
    +-- refundPayment()
        +-- [2-star TESTED] Full refund
        +-- [1-star TESTED] Partial refund (checks non-throw only)

-------------------------------------
COVERAGE: 3/5 paths tested (60%)
QUALITY:  3-star: 1  2-star: 1  1-star: 1
GAPS: 2 paths need tests
-------------------------------------
```

**Fast path:** All paths covered -> "Test review: All new code paths have test coverage." Continue.

**Step 5. Add missing tests to the plan:**

For each GAP identified in the diagram, add a test requirement to the plan. Be specific:
- What test file to create (match existing naming conventions)
- What the test should assert (specific inputs -> expected outputs/behavior)
- Whether it's a unit test or E2E test

**STOP.** For each issue found in this section, present it individually. Only proceed after ALL issues are resolved.

### 4. Performance review
Evaluate:
* N+1 queries and database access patterns.
* Memory-usage concerns.
* Caching opportunities.
* Slow or high-complexity code paths.

**STOP.** For each issue found in this section, present it individually. Only proceed after ALL issues are resolved.

## Required outputs

### "NOT in scope" section
Every plan review MUST produce a "NOT in scope" section listing work that was considered and explicitly deferred, with a one-line rationale for each item.

### "What already exists" section
List existing code/flows that already partially solve sub-problems in this plan, and whether the plan reuses them or unnecessarily rebuilds them.

### Diagrams
The plan itself should use ASCII diagrams for any non-trivial data flow, state machine, or processing pipeline. Additionally, identify which files in the implementation should get inline ASCII diagram comments.

### Failure modes
For each new codepath identified in the test review diagram, list one realistic way it could fail in production (timeout, nil reference, race condition, stale data, etc.) and whether:
1. A test covers that failure
2. Error handling exists for it
3. The user would see a clear error or a silent failure

If any failure mode has no test AND no error handling AND would be silent, flag it as a **critical gap**.

### Parallelization strategy

Analyze the plan's implementation steps for parallel execution opportunities.

**Skip if:** all steps touch the same primary module, or the plan has fewer than 2 independent workstreams. In that case, write: "Sequential implementation, no parallelization opportunity."

**Otherwise, produce:**

1. **Dependency table** — for each implementation step/workstream:

| Step | Modules touched | Depends on |
|------|----------------|------------|
| (step name) | (directories/modules) | (other steps, or —) |

2. **Parallel lanes** — group steps into lanes:
   - Steps with no shared modules and no dependency go in separate lanes (parallel)
   - Steps sharing a module directory go in the same lane (sequential)
   - Steps depending on other steps go in later lanes

3. **Execution order** — which lanes launch in parallel, which wait.

4. **Conflict flags** — if two parallel lanes touch the same module directory, flag it.

### Completion summary
At the end of the review, fill in and display this summary:
- Step 0: Scope Challenge — ___ (scope accepted as-is / scope reduced per recommendation)
- Architecture Review: ___ issues found
- Code Quality Review: ___ issues found
- Test Review: diagram produced, ___ gaps identified
- Performance Review: ___ issues found
- NOT in scope: written
- What already exists: written
- Failure modes: ___ critical gaps flagged
- Parallelization: ___ lanes, ___ parallel / ___ sequential

## Formatting rules
* NUMBER issues (1, 2, 3...) and LETTERS for options (A, B, C...).
* Label with NUMBER + LETTER (e.g., "3A", "3B").
* One sentence max per option. Pick in under 5 seconds.
* After each review section, pause and ask for feedback before moving on.
* **One issue = one discussion.** Never combine multiple issues into one question.
* Describe the problem concretely, with file and line references.
* Present 2-3 options, including "do nothing" where that's reasonable.
* **Escape hatch:** If a section has no issues, say so and move on.

## Unresolved decisions
If the user does not respond to an issue or interrupts to move on, note which decisions were left unresolved. At the end of the review, list these as "Unresolved decisions that may bite you later" — never silently default to an option.
