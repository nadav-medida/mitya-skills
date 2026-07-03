---
name: splitting-prs
description: Use when splitting an oversized PR, branch, or current work into multiple reviewable pull requests, especially when the user gives a parent Linear issue or asks for a stacked PR chain.
---

# Splitting PRs

Split one large branch into reviewable PRs that are easy to follow, correctly linked, and CI-ready.

## Core Rules

- **REQUIRED SUB-SKILL:** Use `pr` for branch, Linear, title, push, and PR body conventions.
- Do not create branches, commits, pushes, or PRs until the user approves the split plan.
- Save a recoverable backup ref before moving work.
- Never use destructive git commands or delete the original branch/PR unless the user explicitly asks.
- Stage only named files or hunks. Never use `git add .` or `git add -A`.

## Linear And Names

When the user gives a parent Linear issue, every split PR gets its own parallel sub-issue under that parent.

Pick a short feature name for the stack, then name every Linear issue:

```text
<short feature> PR <N>: <what this one does>
```

Use the same numbering in PR titles:

```text
[ENG-XXXX] <short feature> PR <N>: <what this one does>
```

Example:

```text
Auto-overlay edges PR 1: Split helper modules
Auto-overlay edges PR 2: Refactor frame orchestration
Auto-overlay edges PR 3: Add edge creation endpoint
Auto-overlay edges PR 4: Add batch endpoint
```

## Stack Shape

Default to independent PRs off the default branch. Stack only when later slices depend on earlier slices. For stack mechanics (bases, `Stacks on #N`, sibling Linear issues) follow **`pr`** → Stacked PRs.

Split-specific:

- PR bodies explain setup-looking changes by naming the later PR or behavior they enable.
- If a lower PR receives a fix, merge or cherry-pick it into every dependent branch, rerun checks, and push dependents so CI checks the updated head commit.

## Finalize Each Slice

Run `/finalize-feature` on each branch in stack order. That skill owns the per-repo checks, lint fixes, commits, push/upstream tracking, Linear links, and PR creation/update.

## Superseded PRs

Leave the original oversized PR open until replacement PRs are created and pushed. Then close only the PRs that are clearly superseded or irrelevant, and include links to the replacement stack.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Creating child issues without PR numbers | Name every issue and PR with `PR <N>` |
| Nesting PR 2's issue under PR 1's issue | Create parallel sub-issues under the parent Linear issue |
