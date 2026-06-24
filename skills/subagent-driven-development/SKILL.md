---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute plan by dispatching a fresh implementer subagent per task. Review depth is configurable via **review mode**.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Fresh subagent per outlined task = fast, focused iteration. The controller should not implement plan tasks directly; every task listed in the plan is delegated unless the user explicitly asks for direct implementation.

**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.

## Review Modes

Pick a mode at the start of the run. **Default is `default`** unless the user names another mode.

| Mode | Per-task implementers | Per-task spec + quality reviews | Final feature review |
|------|----------------------|---------------------------------|---------------------|
| **`default`** | Yes | No | No |
| **`review-only-when-done`** | Yes | No | Yes |
| **`full-flow`** | Yes | Yes (spec, then quality) | Yes |

**How users select a mode:**
- Unspecified → `default`
- "review when done", "final review only", "review at the end" → `review-only-when-done`
- "full flow", "full reviews", "two-stage review", "spec and quality review" → `full-flow`
- "no reviews" → `default` (same as default; implementer self-review only)

**Mode overrides:** If the user contradicts the chosen mode mid-run (e.g. "no reviews" during `full-flow`), follow the latest explicit instruction for the remainder of the run.

## When to Use

```dot
digraph when_to_use {
    "Have implementation plan?" [shape=diamond];
    "Tasks mostly independent?" [shape=diamond];
    "Stay in this session?" [shape=diamond];
    "subagent-driven-development" [shape=box];
    "executing-plans" [shape=box];
    "Manual execution or brainstorm first" [shape=box];

    "Have implementation plan?" -> "Tasks mostly independent?" [label="yes"];
    "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
    "Tasks mostly independent?" -> "Stay in this session?" [label="yes"];
    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
    "Stay in this session?" -> "subagent-driven-development" [label="yes"];
    "Stay in this session?" -> "executing-plans" [label="no - parallel session"];
}
```

**vs. Executing Plans (parallel session):**
- Same session (no context switch)
- Fresh subagent per task (no context pollution)
- Review depth chosen via review mode
- Faster iteration (no human-in-loop between tasks)

## The Process

At start: read plan, extract all tasks with full text, note context, pick review mode, create TodoWrite.

### Per task (all modes)

```dot
digraph per_task {
    rankdir=TB;

    "Dispatch implementer subagent (./implementer-prompt.md)" [shape=box];
    "Implementer subagent asks questions?" [shape=diamond];
    "Answer questions, provide context" [shape=box];
    "Implementer subagent implements, tests, commits, self-reviews" [shape=box];
    "Review mode?" [shape=diamond];
    "Dispatch spec reviewer (./spec-reviewer-prompt.md)" [shape=box];
    "Spec compliant?" [shape=diamond];
    "Implementer fixes spec gaps" [shape=box];
    "Dispatch code quality reviewer (./code-quality-reviewer-prompt.md)" [shape=box];
    "Quality approved?" [shape=diamond];
    "Implementer fixes quality issues" [shape=box];
    "Mark task complete in TodoWrite" [shape=box];

    "Dispatch implementer subagent (./implementer-prompt.md)" -> "Implementer subagent asks questions?";
    "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
    "Answer questions, provide context" -> "Dispatch implementer subagent (./implementer-prompt.md)";
    "Implementer subagent asks questions?" -> "Implementer subagent implements, tests, commits, self-reviews" [label="no"];
    "Implementer subagent implements, tests, commits, self-reviews" -> "Review mode?";
    "Review mode?" -> "Mark task complete in TodoWrite" [label="default or review-only-when-done"];
    "Review mode?" -> "Dispatch spec reviewer (./spec-reviewer-prompt.md)" [label="full-flow"];
    "Dispatch spec reviewer (./spec-reviewer-prompt.md)" -> "Spec compliant?";
    "Spec compliant?" -> "Implementer fixes spec gaps" [label="no"];
    "Implementer fixes spec gaps" -> "Dispatch spec reviewer (./spec-reviewer-prompt.md)" [label="re-review"];
    "Spec compliant?" -> "Dispatch code quality reviewer (./code-quality-reviewer-prompt.md)" [label="yes"];
    "Dispatch code quality reviewer (./code-quality-reviewer-prompt.md)" -> "Quality approved?";
    "Quality approved?" -> "Implementer fixes quality issues" [label="no"];
    "Implementer fixes quality issues" -> "Dispatch code quality reviewer (./code-quality-reviewer-prompt.md)" [label="re-review"];
    "Quality approved?" -> "Mark task complete in TodoWrite" [label="yes"];
}
```

### After all tasks

| Mode | Next step |
|------|-----------|
| `default` | **superpowers:finishing-a-development-branch** |
| `review-only-when-done` | Dispatch final feature reviewer → then finishing |
| `full-flow` | Dispatch final feature reviewer → then finishing |

Final feature reviewer uses the **controller's currently selected model** (see Subagent Model Selection). Per-task subagents use the **cheap tier** (see Subagent Model Selection).

## Subagent Model Selection

Two tiers. Pick once at run start; reuse for every dispatch in that tier.

| Tier | Used for | Model |
|------|----------|-------|
| **Cheap** | Per-task implementers, spec reviewers, code quality reviewers, fix passes | See cheap tier below |
| **Controller** | Final feature reviewer only (`review-only-when-done`, `full-flow`) | Controller's currently selected model, unchanged |

### Cheap tier (per-task subagents)

1. **`composer-2.5-fast`** if it appears in the Task tool's allowed model list.
2. **Otherwise** the controller's current model at **low thinking** — same model family/slug the session is running, with the lowest thinking tier available for that family in the allowlist (e.g. `-fast` or `-medium` variants; do not pick a higher-thinking slug than the controller is using).

If the user explicitly requests `composer-2.5-fast` and it is available, use it for all cheap-tier dispatches.

**Do not** silently upgrade cheap-tier subagents to the controller model or a higher-thinking variant "to be safe."

### Controller tier (final feature review)

Dispatch with the **controller's currently selected model** — full thinking, no downgrade to cheap tier or low thinking. This is the one subagent that should apply broad judgment across the full implementation.

### Escalation

Only use a non-cheap-tier model for **per-task** work when the user explicitly requested it, or you stopped and asked for approval. If a task looks too hard for the cheap tier, break it down or ask before escalating.

**Task complexity signals:**
- Touches 1-2 files with a complete spec → cheap tier
- Touches multiple files with integration concerns → consider splitting before escalating
- Requires design judgment or broad codebase understanding → ask before escalating per-task model

## Handling Implementer Status

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:**
- `default` or `review-only-when-done` → mark task complete, next task
- `full-flow` → proceed to spec compliance review

**DONE_WITH_CONCERNS:** Read concerns before proceeding. If about correctness or scope, address before moving on (and before per-task reviews in `full-flow`). Observations only → note and continue per mode.

**NEEDS_CONTEXT:** Provide missing context and re-dispatch.

**BLOCKED:** Assess the blocker:
1. Context problem → provide context, re-dispatch same model
2. Needs more reasoning → break down or ask before stronger model
3. Task too large → split into smaller pieces
4. Plan is wrong → escalate to the human

**Never** ignore an escalation or force the same model to retry without changes.

## Prompt Templates

- `./implementer-prompt.md` - Dispatch implementer subagent
- `./spec-reviewer-prompt.md` - Dispatch spec compliance reviewer (`full-flow` only)
- `./code-quality-reviewer-prompt.md` - Dispatch code quality reviewer (`full-flow` only)

Final feature reviewer (`review-only-when-done` and `full-flow`): use **superpowers:requesting-code-review** with the controller tier model.

## Example Workflow (`default` mode)

```
You: I'm using Subagent-Driven Development (default mode) to execute this plan.

[Read plan, extract tasks, create TodoWrite]

Task 1: Hook installation script

[Dispatch implementer subagent — cheap tier]

Implementer: DONE — implemented, 5/5 tests, self-review clean, committed

[Mark Task 1 complete — no review subagents]

Task 2: Recovery modes

[Dispatch implementer subagent]

Implementer: DONE — 8/8 tests, committed

[Mark Task 2 complete]

...

[All tasks done → superpowers:finishing-a-development-branch]
```

### `review-only-when-done` add-on

After all tasks complete, dispatch one final feature reviewer using the controller tier. Fix any issues it finds, re-review until approved, then finishing.

### `full-flow` add-on (per task, after implementer DONE)

```
[Dispatch spec reviewer — cheap tier]
Spec reviewer: ✅ or ❌ → implementer fixes → re-review until ✅

[Dispatch code quality reviewer — cheap tier]
Code reviewer: ✅ or ❌ → implementer fixes → re-review until ✅

[Mark task complete]
```

After all tasks: final feature reviewer on controller tier, then finishing.

## Advantages

**vs. Manual execution:**
- Subagents follow TDD naturally
- Fresh context per task
- Parallel-safe (subagents don't interfere)
- Subagent can ask questions before and during work

**vs. Executing Plans:**
- Same session (no handoff)
- Continuous progress
- Tunable review cost via review mode

**Quality gates by mode:**
- All modes: implementer self-review
- `review-only-when-done`: one holistic final review (controller tier)
- `full-flow`: per-task spec + quality gates plus final review

**Cost by mode:**
- `default`: one subagent per task (lowest)
- `review-only-when-done`: one sub task + one final review
- `full-flow`: implementer + two reviewers per task + final review (highest; catches issues earliest)

## Red Flags

**Never:**
- Start implementation on main/master without explicit user consent
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make subagent read plan file (provide full text instead)
- Skip scene-setting context
- Ignore implementer questions
- Use the **controller tier** for the **final** feature reviewer
- Silently upgrade **cheap-tier** per-task subagents to controller tier or higher thinking
- Silently downgrade the final reviewer to cheap tier

**In `full-flow` only — never:**
- Skip spec or code quality review for a completed task
- Proceed with unfixed review issues
- Accept "close enough" on spec compliance
- Skip review loops
- Let implementer self-review replace per-task reviews
- Start code quality review before spec compliance is ✅
- Move to next task while either per-task review has open issues

**If subagent asks questions:** Answer completely before they proceed.

**If reviewer finds issues (`full-flow` or final review):** Implementer or fix subagent addresses them; reviewer re-reviews until approved.

**If subagent fails task:** Dispatch fix subagent with specific instructions; don't fix manually (context pollution).

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - Isolated workspace
- **superpowers:writing-plans** - Plan this skill executes
- **superpowers:requesting-code-review** - Final reviewer and per-task quality templates
- **superpowers:finishing-a-development-branch** - After all tasks (and final review when applicable)

**Subagents should use:**
- **superpowers:test-driven-development** - TDD for each task

**Alternative workflow:**
- **superpowers:executing-plans** - Parallel session instead of same-session execution
