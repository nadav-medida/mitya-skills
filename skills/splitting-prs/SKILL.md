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

When splitting an existing branch, first find that branch's current PR and linked Linear issue; use that issue as the parent for replacement issues. If either is missing, create a new parent issue. When the user gives a parent Linear issue directly, every split PR gets its own parallel sub-issue under that parent.

For stacked PRs, create a Linear dependency chain while keeping all issues parallel under the parent: PR N's issue should be `blockedBy` PR N-1's issue. For multi-repo splits, apply this chain only within each repo-local stack; do not block issues across repos unless the PR stack itself crosses repo boundaries.

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

Default to independent PRs off the default branch. Stack only when later slices depend on earlier slices.

Stack tooling is **`gh stack`** (extension `github/gh-stack`). Never use Graphite CLI (`gt track`, `gt`, etc.) for stack registration — even if old PRs still show Graphite comments.

For Linear sibling issues and Medida title/body conventions, follow **`pr`** → Stacked PRs. Manual `gh pr create --base` alone is not enough: GitHub must also get a stack object via `gh stack`.

Split-specific:

- PR bodies explain setup-looking changes by naming the later PR or behavior they enable.
- After stacked branches exist locally (bottom→top), adopt them: `gh stack init --base <trunk> <bottom> … <top>`. Push with `gh stack push`. Create/update Medida PRs via **`pr`** / `/finalize-feature` (so titles keep `[ENG-XXXX]`), then register the GitHub stack with `gh stack link <bottom> … <top>` (or `gh stack sync` once ≥2 open PRs exist). Do not stop after `--base` chaining.
- To append an existing dependent PR onto the new tip: `gh stack link <bottom> … <new-top> <dependent-pr-or-branch>` (or `gh stack link <stack-number> <dependent>`). Fix the dependent’s git parent first if its commits still sit on a superseded branch.
- If a lower PR receives a fix, land it there, then `gh stack sync` (or `gh stack rebase` + `gh stack push`) so every dependent and PR base moves with the tip. Do not leave dependents on a stale parent.

| Excuse | Reality |
|---|---|
| "`gh pr --base` is enough" | Bases without `gh stack link`/`submit`/`sync` leave no GitHub stack map for reviewers. |
| "Graphite comments still appear / `gt` still works" | Stack tooling is `gh stack`. Ignore leftover Graphite UI. |
| "`gh stack submit --auto` covers titles" | Medida requires `[ENG-XXXX]` via `pr`; finalize then `link`, or submit then edit titles. |

## Finalize Each Slice

Run `/finalize-feature` on each branch in stack order. That skill owns the per-repo checks, lint fixes, commits, push/upstream tracking, Linear links, and PR creation/update. After the slices have PRs, run `gh stack link` / `gh stack sync` if the GitHub stack object is still missing.

## Superseded PRs

Leave the original oversized PR open until replacement PRs are created and pushed. Then close only the PRs that are clearly superseded or irrelevant, and include links to the replacement stack.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Creating child issues without PR numbers | Name every issue and PR with `PR <N>` |
| Nesting PR 2's issue under PR 1's issue | Create parallel sub-issues under the parent Linear issue |
| Using `gt track` or skipping `gh stack link`/`sync` | Register stacks with `gh stack` only |
