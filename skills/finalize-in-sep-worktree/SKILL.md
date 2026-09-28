---
name: finalize-in-sep-worktree
description: >-
  Use when the user says /finalize-in-sep-worktree, or wants finalize-feature
  and a separate worktree in one invocation.
disable-model-invocation: true
---

# Finalize in a separate worktree

A **union**, not a rewrite.

**REQUIRED SUB-SKILL:** Read and follow `/sep-worktree` (`/Users/xallt/.claude/skills/sep-worktree/SKILL.md`).
**REQUIRED SUB-SKILL:** Read and follow `/finalize-feature` (`/Users/xallt/.claude/skills/finalize-feature/SKILL.md`).

Do not recap those skills here. Skipping a read because you "already know" them is not running this union.

## Sequence

1. **Create** — `/sep-worktree` Create. After this, every edit, check, commit, and `gh` command runs in `.worktrees/$path`.
   - Dirty files on the main checkout are **not** in the new tree. Move the work in (stash, copy, or checkout) before finalize. Do not commit it on `main`.
   - Already on the feature branch you are shipping: add a worktree **for that branch**. Do not open a second unused branch from `origin/main`.
   - Already inside this task's worktree: skip Create.
2. **Finalize** — full `/finalize-feature` inside that worktree. Checks on the main checkout, or checks without the required push/PR, is not done.
3. **Teardown** — `/sep-worktree` Teardown from the **main** repo root (not from inside the worktree). "PR is up" or "reviewer might look locally" is not a keep reason unless a skip-removal condition in `/sep-worktree` applies.

Invoking this skill makes the worktree **mandatory**. Authority, a small diff, dinner, or "the files are already on main" does not skip the tree, the sub-skill reads, or teardown.
