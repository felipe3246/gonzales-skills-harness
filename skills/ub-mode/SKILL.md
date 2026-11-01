---
name: ub-mode
description: >
  Default coding discipline for this harness. Every code change follows First
  Make it Work, then Make it Right, then Practice. Use when the user runs
  /ub-mode, asks for these principles, or when implementing, fixing, refactoring,
  or verifying code — including when briefing a sub-agent whose job is coding.
---

# ub-mode

Adapted from [unclebob/ub-mode](https://github.com/unclebob/ub-mode) for this
harness. This is the **default coding workflow**: follow it whenever you write
or change code, and put the same contract in the brief of any sub-agent you
spawn whose job is to implement, fix, refactor, or verify code. Research,
grilling, teaching, and diagram agents do not need it.

Trivial one-line edits (typo, rename) may use judgment and skip the full loop.

Every non-trivial change follows:

1. **First Make it Work**
2. **Then Make it Right**
3. **Practice**

## How this fits other skills

- Non-trivial change with unclear verification → run `verification-planning`
  first; then execute under this skill.
- Domain terms / illegal states → keep or update `GLOSSARY.md` via
  `domain-modeling`; do not invent a parallel glossary.
- Module seams / deep interfaces → use `codebase-design` vocabulary when
  redesigning structure.
- Decision still fuzzy → `grill-me` / `grilling` before coding.

# First Make it Work

## Laziness Protocol

- One decision lives in one place.
- Ship the smallest edit that solves the problem.

## Foundational Thinking

- Get the data shape right before you write the logic.
- Do first whatever helps every later phase.
- If a concurrent writer would matter, do not share state.

## TDD

- Write the failing test before you change the code.
- See it fail for the reason you expect.
- Make the smallest change that makes it pass.
- If an honest test is impractical, do not write a bad one — say so and use
  the next-best evidence from the project's verification path.

## Redesign From First Principles

- Do not bolt a new requirement onto the old design.
- Ask what you would have built if it had been there from the start, think
  that through, and deliver it in pieces.
- Scope: this applies to the code the request already touches. It does not
  license rewriting adjacent code that works (guidelines principles 2 and 3).
  If the better design needs a wider change, propose it; do not do it.

## Attack the Premise

- When two fixes fail the same check, stop. They share an assumption.
- Write that assumption in one sentence and test it directly.
- Do not attempt a third fix until the assumption is confirmed or dropped.

## Subtract Before You Add

- Take complexity out before you add anything — inside the touched scope.

## Outcome-Oriented Execution

- Aim at the end state you can check.
- A break in the middle is allowed when you planned it and can undo it.

## Build the Lever

- If the work is not obvious at a glance, build the tool that does it.
- Do one unit by hand, then make the tool match that unit.

## Architecture

### Model the Domain

- Put the domain in a structure that makes the illegal states impossible.
- Maintain domain terms in the project's `GLOSSARY.md` (see `domain-modeling`).
- If the code is already clear and local, leave it.

### Boundary Discipline

- Check the data where it enters.
- Inside, trust it.
- Keep the business logic in a pure function when practical.

### Type System Discipline

- Make the illegal value impossible to write.
- Parse outside data once, where it comes in.
- Do not silence the compiler / typechecker.

### Make Operations Idempotent

- Running it twice, or running it after a crash halfway through, ends in the
  same state.

### Separate Before Serializing Shared State

- If they do not need the same mutable thing, give each its own.
- If they do, allow one writer, and enforce that in the structure.

# Then Make it Right

## Fix Root Causes

- Reproduce it.
- Fix the cause.
- A guard that only hides the crash is not a fix.

## Sequence work into verifiable units

- Finish one small unit and check it.
- Then start the next.

## Test Behavior, Not Implementation

- The test calls the code the way its user does and checks the result that
  user would see.
- If the test would still pass when every function returned nothing, throw it
  out.

## Quality gates (soft)

Prefer the project's own gates when they exist. When Uncle Bob's companion
CLIs are installed, use them; otherwise apply the same *intent* with whatever
the stack already has (coverage, complexity/lint rules, duplication detectors,
mutation testing). Do **not** fail the workflow only because a companion CLI
is missing from PATH.

### Complexity / CRAP

- Target: keep each touched function under a CRAP-like threshold of **10**
  (or the project's documented limit).
- Tool preference: [crapper](https://github.com/unclebob/crapper) if available;
  else project coverage + complexity reports.
- Reduce by splitting, by testing, or both. Case statements: only reduce when
  the split clarifies.

### Duplication

- Eliminate structural duplication at similarity **≥ 0.8** in code you touched
  or introduced.
- Tool preference: [dryer](https://github.com/unclebob/dryer) if available;
  else `jscpd` / IDE dup findings / careful review.

### Mutation / dead code

- Cover the uncovered. Kill survivors. Delete dead code you own from this
  change.
- Tool preference: [mutator](https://github.com/unclebob/mutator) if available;
  else the project's mutation tool or a strong coverage + review pass.

Refactoring under these gates stays **scoped to the area you changed** (see
guidelines: surgical changes). Do not clean the whole repository.

## Refactoring

- Pin what the code does.
- Change the structure.
- Prove the behavior did not change.

# Practice

## Keep a Log

- Keep a short log of the decisions you made and why.
- Report it upon completion, not every tool call.

## Guard the Context Window

- Keep the main thread small.
- Send the bulk elsewhere, and keep the summary.

## Worktree Cleanup

- Cleanup follows guideline principle 5 exactly: delete only scratch you
  created; never user files, project files, dependency caches, or
  tool-managed state. When in doubt, leave it and list the path.
- Uncommitted work waits for a decision.

## Commit and Push

- When the user asked for commits, or the project workflow expects them,
  commit in small ordered commits. Each commit says why, what changed, and
  how you proved it.
- Otherwise leave the work uncommitted and say so in the report; committing
  and pushing are the user's call.
- Never push to the default branch unless explicitly told to.

## Briefing coding sub-agents

When you spawn a sub-agent (or hand off) whose job is implementation, fixing,
refactoring, or code verification, copy the "Coding default (ub-mode)"
paragraph from `guidelines/AGENTS.md` into the brief. That paragraph is the
single source of the contract; do not paraphrase it here.
