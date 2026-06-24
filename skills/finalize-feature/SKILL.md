---
name: finalize-feature
description: >-
  Use when the user says finalize feature, ready for PR, finalize the branch, or
  invokes /finalize-feature — including re-finalizing a branch that already has
  an open PR with failing CI or review feedback. Not for checks-only runs.
disable-model-invocation: true
---

# Finalize Feature

Prepare a branch for review: **triage (existing PR) → checks → commit → push → PR (+Linear)**. Invoking this means the full workflow through a pushed branch — not checks alone. **Always push when done** (see Push below).

## Workflow

0. **Existing PR** — if `gh pr list --head <branch>` finds one, triage before local checks:
   - **Conflicts** — first, check whether the PR currently conflicts with its base (for example, `gh pr view <num> --json mergeStateStatus,baseRefName`) or `git status` shows an in-progress merge/rebase/cherry-pick or unmerged paths. If conflicts exist, rebase onto the PR base and resolve them before CI or review triage:
     - Inspect conflicted files and the active operation (`git status`, `git diff --name-only --diff-filter=U`, and the PR/base context). Prefer the existing codebase/base-branch patterns over blindly taking either side.
     - After resolving, stage the files and continue the operation (`git rebase --continue`, `git merge --continue`, or `git cherry-pick --continue`). If the correct resolution is ambiguous or changes PR scope, stop and ask.
     - Then continue existing-PR triage. Do not abort the operation unless the user explicitly asks or the branch cannot be safely recovered.
   - **CI** — `gh pr checks <num>` (or Actions tab). Fix failures you can address locally, re-run local gates, commit. One actionable fix pass only; after pushing the fix, do not continue monitoring or loop on newly reported CI failures unless the user invoked `babysit`.
   - **Review feedback** — inline review comments, submitted reviews, issue-level PR comments, bot findings (Greptile, Bugbot, etc.), and human comments about code issues, quality, or requested changes. **Address actionable items** as part of this workflow; skip pure nits or subjective disagreements unless the user said otherwise.
     - Check all feedback surfaces: inline review comments, submitted reviews, and issue-level PR comments. Bot findings can appear as issue-level comments when inline comments are outside the diff; search for bot markers such as `greptile_failed_comments`, `bugbot`, and confidence summaries.
     - Keep review-fix changes narrowly scoped to the comment. Do not restore or reintroduce adjacent prior behavior from the base branch unless the comment explicitly asks for it; if the intended scope is ambiguous, stop and ask.
   - If nothing actionable remains, proceed.
1. **Scope** — which repo/branch(es)? May be multi-repo; if unclear, ask.
2. **Branch** — if not on a feature branch, create `feature/<short-kebab-description>` off `main`. Descriptive kebab names only, no ticket IDs (details in Medida → Branch).
3. **Commit** — commit uncommitted changes with a short message before checks.
4. **Checks** — run the repo's linter **with auto-fix enabled**, then typecheck / tests. Use each repo's fix command (not check-only lint). If the linter changes files, commit those fixes (e.g. `lint fix`) before continuing. Detect commands from the project (package.json scripts, Makefile, AGENTS.md/CLAUDE.md). One straightforward fix attempt, re-run once; if still failing, **stop and report** — don't keep iterating.
5. **Push** — **required.** Push the branch to origin and confirm upstream tracking (`git status -sb` shows `...origin/<branch>`). Follow **`pr`** skill → Push. Do not stop after local checks without pushing unless blocked — report the blocker.
6. **PR** — read and follow the **`pr`** skill (`~/.claude/skills/pr/SKILL.md` or `~/.agents/skills/pr/SKILL.md`). It owns draft-default, title format, sub-issues, and stacked PR bases.
   - **New PR** — create per `pr` skill.
   - **Existing PR** — fix title/Linear link if wrong. **Update PR body only when branch scope changed** (new commits, files, or behavior vs the PR base — compare `git diff <base>...HEAD` to what the description already covers). Do not rewrite an accurate description for lint-only or review-fix follow-ups.

## Medida

| Repo | Path | GitHub |
|------|------|--------|
| medida-web | `medida-web/` | `medidai/medida-web` |
| medida-3d | `medida-3d/` | `medidai/medida-3d` |
| medida-ui | `medida-ui/` | `medidai/medida-ui` |

**Scope** — single-repo cwd → that repo only. Parent folder (e.g. `medida/`) → infer changed repos from context and finalize in dependency order. Unclear → ask.

**Branch** — PR base is usually `main` (stacked PRs use the stack base). No Linear IDs in branch names (`feature/postscan-warnings`, not `feature/ENG-6868-...` or `mitya/eng-6868-...`).

**Commit**
- medida-web / medida-3d — casual one-liner (`lint fix`, `Move files`, `Auto overlays status`); a second line only if complicated.
- medida-ui — **exactly one commit per PR**; squash before opening. Headline matches the PR title (`[ENG-XXXX] Title`, or plain title without Linear). No verbose multi-paragraph commits.

**Checks** — per repo; one fix attempt, re-run once, else stop and report. Always run the linter's **fix** step first — finalizing is not just verifying lint passes, it's applying whatever auto-fixes the linter offers and committing them.

| Repo | Linter fix | Then |
|------|------------|------|
| medida-web | `pnpm lint:fix` | `pnpm typecheck` |
| medida-3d | `uv run --no-sync ruff check --fix <changed Python files>` | `uv run --no-sync pyright`, targeted pytest via `uv run --no-sync pytest ...` when relevant |
| medida-ui | `scripts/lint.sh` (`swiftlint --fix && swiftlint`) | — |

- medida-web: CI also runs `pnpm format:check` — skip unless asked. If `pnpm typecheck` fails with missing-module / dependency errors (`Cannot find module`), run `pnpm install` once and retry before reporting failure.
- medida-3d: run ruff on changed Python files only. Run pyright for the full repo/workspace because typing changes can affect far-away imports and call sites. Use `git diff <base>...HEAD --name-only` to choose ruff/test targets; infer `<base>` from `gh pr view --json baseRefName`, conversation, or ask. Run Python tools through `uv run --no-sync` from the relevant workspace so PATH, VIRTUAL_ENV, and interpreter selection match CI. Don't run full Docker CI (`tools/ci.sh check`) unless asked.
- medida-ui: fix all warnings; only `// swiftlint:disable type_body_length` on architecturally large files (e.g. `CameraScanView`). Don't run full `xcodebuild` unless asked. No GitHub Actions CI — local SwiftLint is the gate.

**Multi-repo order** — open PRs in dependency order: 1) medida-3d (migration/schema/API), 2) medida-web (frontend/orpc), 3) medida-ui (iOS). Only repos that changed; stack bases when one PR depends on another. Each PR gets its own Linear sub-issue (see pr).

**Don't**
- Push without a finalize request (this skill is that request).
- Stop after local checks without pushing — finalize ends with `git push`.
- Rewrite an existing PR description when scope is unchanged.
- Make a ready-to-review PR by default — draft unless asked.
- Auto-fix beyond one straightforward attempt.
- Open a medida-ui PR with multiple commits — squash first.
