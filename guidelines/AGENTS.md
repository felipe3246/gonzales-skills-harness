# Coding Guidelines

Behavioral guidelines for coding agents. Adapted from Andrej Karpathy's
observations on LLM coding pitfalls, via multica-ai/andrej-karpathy-skills
(MIT), with additions.

**Tradeoff:** these guidelines bias toward caution over speed. For trivial
tasks such as a typo fix, use judgment.

**Skills come first.** When a skill or workflow with its own process applies
(brainstorming, test-driven development, systematic debugging, verification),
follow that process. These guidelines are the default when none does.

**Project instructions win.** When a project's own CLAUDE.md, AGENTS.md or
steering files contradict these guidelines, follow the project.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them. Don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
- When running unattended (a loop, a background agent, a non-interactive
  run) you cannot ask. Take the most conservative interpretation, state the
  assumption you proceeded on, and flag it in the final report.

Example. Request: "Make the search faster."
- Wrong: add caching, indexes and async in one pass, 200 lines, without
  asking which "faster" matters.
- Right: "Faster could mean response time, throughput, or perceived speed.
  Current p50 is ~500ms. Which one matters here?" Then do that one.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes,
simplify.

Example. Request: "Add a function to calculate discount."
- Wrong: a `DiscountStrategy` base class, `PercentageDiscount`,
  `FixedDiscount`, a `DiscountConfig` dataclass and a `DiscountCalculator`.
  Thirty lines of setup for one multiplication.
- Right:
  ```python
  def calculate_discount(amount: float, percent: float) -> float:
      return amount * (percent / 100)
  ```
  Add the second discount type when the second discount type exists.

The overcomplicated version isn't obviously wrong; it follows real design
patterns. The problem is timing: complexity added before it's needed.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it. Don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

Example. Request: "Add logging to the upload function."
- Wrong: add logging, and also switch quotes to double, add type hints and
  a docstring, and rewrite the if/else return into a boolean variable.
- Right: add the logger import and the logger calls, in single quotes
  because the file uses single quotes, and change nothing else.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it
work") require constant clarification.

Example. Request: "The sorting breaks when there are duplicate scores."
- Wrong: change the sort key immediately, without confirming the bug.
- Right: write a test with two equal scores that asserts a deterministic
  order, run it and watch it fail, fix with a stable key, watch it pass.

## 5. Clean Up Temporary Work

**Leave the machine as you found it, except for the deliverable.**

Temporary work is anything you created to get the job done that is not part
of the result: scratch scripts, downloaded archives and what you extracted
from them, repositories cloned only for reading, throwaway fixtures, build or
export output outside the project, worktrees made for an experiment, files
under the system temp directory.

- Before reporting a task as done, delete the temporary work you created.
  Prefer creating it under one dedicated directory so cleanup is a single
  removal.
- When you delegate to sub-agents, put this instruction in their brief and
  check that they followed it. Sub-agents may not load these guidelines.
- Delete only what you created as scratch. Never remove user files, project
  files, dependency caches, tool-managed state, or anything that existed
  before you started.
- When in doubt whether something is temporary, leave it and list its path
  in your report.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer
rewrites due to overcomplication, clarifying questions before implementation
rather than after mistakes, and no leftover scratch files after a task.
