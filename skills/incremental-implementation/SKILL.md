---
name: incremental-implementation
description: Deliver multi-file changes in thin, verified, committed slices.
disable-model-invocation: true
---

# Incremental Implementation

## Overview

Build in thin vertical slices — implement one piece, test it, verify it, then expand. Avoid implementing an entire feature in one pass. Each increment should leave the system in a working, testable state. This is the execution discipline that makes large features manageable.

## When to Use

- Implementing any multi-file change
- Building a new feature from a task breakdown
- Refactoring existing code
- Any time you're tempted to write more than ~100 lines before testing

**When NOT to use:** Single-file, single-function changes where the scope is already minimal.

Use this skill from Plan mode for multi-slice work. The plan must expose the slice split for human review before Agent-mode execution starts, especially for new features where the atomic boundaries are less obvious than in a refactor.

## The Increment Cycle

```
┌──────────────────────────────────────┐
│                                      │
│   Implement ──→ Test ──→ Verify ──┐  │
│       ▲                           │  │
│       └───── Commit ◄─────────────┘  │
│              │                       │
│              ▼                       │
│          Next slice                  │
│                                      │
└──────────────────────────────────────┘
```

For each slice:

1. **Implement** the smallest complete piece of functionality
2. **Test when logic changed** — run relevant tests for behavior changes; pure refactors, moves, renames, config extraction, and import rewires do not need tests by default when behavior is intentionally unchanged
3. **Verify** — run repo-wide lint/type/build validity checks named by the repo or user; local edits can affect cross-repo imports and types
4. **Commit** — save your progress with a descriptive message
5. **Move to the next slice** — carry forward, don't restart

Per-slice commits are mandatory. Do not silently downgrade commits to "optional" and do not silently accumulate large uncommitted slices.

### Commit authorization

**Invoking this skill is commit authorization** for per-slice commits. That is the point of the skill: slices without commits are not incremental delivery.

- Do **not** ask "May I commit after each slice?"
- Do **not** treat standing user rules like "only commit when asked" as blocking — skill invocation *is* that ask.
- Do **not** leave a verified slice uncommitted and move on.
- Do **not** batch several slices into one commit to avoid committing mid-work.

Only skip commits if the user **explicitly revokes** authorization mid-run (e.g. "don't commit these"). Then report verified-but-uncommitted slices and do not resume committing until they re-authorize or re-invoke the skill.

## Slicing Strategies

### Slice Shape

Prefer the smallest repository-valid slice: one logical move, refactor, or behavior change per commit. If logic must be decoupled before moving code or config, make that decoupling its own slice; the move slice should move already-decoupled declarations and update imports only.

For new features, the plan must explain why each slice is independently valid. If that is unclear, stop in Plan mode and ask the user to review or split the slices further before implementation.

### Vertical Slices (Preferred)

Build one complete path through the stack:

```
Slice 1: Create a task (DB + API + basic UI)
    → Tests pass, user can create a task via the UI

Slice 2: List tasks (query + API + UI)
    → Tests pass, user can see their tasks

Slice 3: Edit a task (update + API + UI)
    → Tests pass, user can modify tasks

Slice 4: Delete a task (delete + API + UI + confirmation)
    → Tests pass, full CRUD complete
```

Each slice delivers working end-to-end functionality.

### Contract-First Slicing

When backend and frontend need to develop in parallel:

```
Slice 0: Define the API contract (types, interfaces, OpenAPI spec)
Slice 1a: Implement backend against the contract + API tests
Slice 1b: Implement frontend against mock data matching the contract
Slice 2: Integrate and test end-to-end
```

### Risk-First Slicing

Tackle the riskiest or most uncertain piece first:

```
Slice 1: Prove the WebSocket connection works (highest risk)
Slice 2: Build real-time task updates on the proven connection
Slice 3: Add offline support and reconnection
```

If Slice 1 fails, you discover it before investing in Slices 2 and 3.

## Implementation Rules

### Rule 0: Simplicity First

Before writing any code, ask: "What is the simplest thing that could work?"

After writing code, review it against these checks:
- Can this be done in fewer lines?
- Are these abstractions earning their complexity?
- Would a staff engineer look at this and say "why didn't you just..."?
- Am I building for hypothetical future requirements, or the current task?

```
SIMPLICITY CHECK:
✗ Generic EventBus with middleware pipeline for one notification
✓ Simple function call

✗ Abstract factory pattern for two similar components
✓ Two straightforward components with shared utilities

✗ Config-driven form builder for three forms
✓ Three form components
```

Three similar lines of code is better than a premature abstraction. Implement the naive, obviously-correct version first. Optimize only after correctness is proven with tests.

### Rule 0.5: Scope Discipline

Touch only what the task requires.

Do NOT:
- "Clean up" code adjacent to your change
- Refactor imports in files you're not modifying
- Remove comments you don't fully understand
- Add features not in the spec because they "seem useful"
- Modernize syntax in files you're only reading

If you notice something worth improving outside your task scope, note it — don't fix it:

```
NOTICED BUT NOT TOUCHING:
- src/utils/format.ts has an unused import (unrelated to this task)
- The auth middleware could use better error messages (separate task)
→ Want me to create tasks for these?
```

### Rule 1: One Thing at a Time

Each increment changes one logical thing. Don't mix concerns:

**Bad:** One commit that adds a new component, refactors an existing one, and updates the build config.

**Good:** Three separate commits — one for each change.

For moves and config extraction, keep decoupling, ownership moves, and import rewires as separate logical slices unless the import rewire is required to make the move compile.

### Rule 2: Keep It Compilable

After each increment, the project must pass the repo-wide validity checks selected by the repo or user. Relevant tests must pass when behavior or logic changed. Don't leave the codebase in a broken state between slices.

## Increment Checklist

After each increment, verify:

- [ ] The change does one thing and does it completely
- [ ] Relevant tests pass when logic changed; no-logic refactors document why tests were skipped
- [ ] Repo-wide lint, typecheck, and build checks selected by the repo or user pass; do not substitute affected-file-only checks unless explicitly asked
- [ ] New behavior works as expected, when the slice adds behavior
- [ ] The change is committed with a descriptive message (skill invocation authorizes this; only omit if the user explicitly revoked commits mid-run)

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll test it all at the end" | Bugs compound. A bug in Slice 1 makes Slices 2-5 wrong. Validate each slice; test slices that change logic. |
| "It's faster to do it all at once" | It *feels* faster until something breaks and you can't find which of 500 changed lines caused it. |
| "These changes are too small to commit separately" | Small commits are free. Large commits hide bugs and make rollbacks painful. |
| "The repo / user rules say don't commit unless asked, so I'll skip or ask first" | Invoking this skill *is* the ask. Commit each verified slice. |
| "User didn't answer the commit question, so leave uncommitted" | Do not ask. Commit. |
| "This refactor is small enough to include" | Refactors mixed with features make both harder to review and debug. Separate them. |
| "It's only a refactor, so I can skip validation" | Skip behavior tests only when logic did not change; still run repo-wide lint/type/build checks. |
| "This feature can't be sliced cleanly, so I'll just implement it all" | Stop in Plan mode and ask the user to review or split the slices further. |
| "Let me run the build command again just to be sure" | After a successful run, repeating the same command adds nothing unless the code has changed since. Run it again after subsequent edits, not as reassurance. |

## Red Flags

- More than 100 lines of code written without running the agreed validation gate
- Multiple unrelated changes in a single increment
- "Let me just quickly add this too" scope expansion
- Skipping the agreed validation gate to move faster
- Build, typecheck, lint, or relevant tests broken between increments
- Large uncommitted changes accumulating
- Asking whether to commit, or treating "only commit when asked" rules as blocking after this skill was invoked
- Leaving verified slices uncommitted while continuing
- Treating commits as optional
- Using incremental implementation directly in Agent mode for a multi-slice task without an accepted plan
- Mixing logic decoupling with a move or config extraction commit
- Building abstractions before the third use case demands it
- Touching files outside the task scope "while I'm here"
- Creating new utility files for one-time operations
- Running the same build/test command twice in a row without any intervening code change

## Verification

After completing all increments for a task:

- [ ] Each increment was individually verified and committed
- [ ] Relevant tests pass for logic changes
- [ ] Repo-wide lint/type/build validity checks pass for every slice
- [ ] New behavior works end-to-end as specified, when the work adds behavior
- [ ] No uncommitted changes remain
