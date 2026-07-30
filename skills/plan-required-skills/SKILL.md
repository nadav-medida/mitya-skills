---
name: plan-required-skills
description: Use when writing, drafting, reviewing, or updating implementation plans, plan headers, execution discipline sections, or plan files that mention TDD, incremental work, subagents, reviews, or other named practices
---

# Plan Required Skills

## Overview

Plans must name the exact skills future agents must read. Do not rely on vague phrases like "use TDD" or "follow subagent-driven development" when a concrete skill exists.

**Core principle:** A plan that depends on a method must start by requiring the skill that defines that method.

## Required Plan Header

When a plan depends on any execution discipline, named methodology, or agent workflow, start the plan body with a requirement to read the matching skills:

```markdown
> **For agentic workers:** REQUIRED SKILLS: Read /test-driven-development (`/Users/xallt/.claude/skills/test-driven-development/SKILL.md`), /subagent-driven-development (`/Users/xallt/.claude/skills/subagent-driven-development/SKILL.md`), and /incremental-implementation (`/Users/xallt/.claude/skills/incremental-implementation/SKILL.md`) before executing this plan.
```

Use the skill identifiers that match the current environment, and include the skill's absolute filesystem path in parentheses immediately after each identifier. Examples: `/test-driven-development` (`/Users/xallt/.claude/skills/test-driven-development/SKILL.md`), `/subagent-driven-development` (`/Users/xallt/.claude/skills/subagent-driven-development/SKILL.md`).

If the current environment uses slash-style skill names, preserve the leading slash. `test-driven-development` is not an acceptable substitute for `/test-driven-development`. If a skill does not have a slash-style identifier, use its listed skill name and still include its absolute filesystem path.

## Incremental Implementation Commit Gate

When a plan requires `/incremental-implementation`, carry forward the commit-authorization gate that skill defines (it is the single source for the gate wording). If repo or higher-priority rules forbid committing without asking, the plan must tell the executor to request authorization before multi-slice work begins.

## Mapping Rule

Before writing the plan's execution instructions:

1. List every practice the plan relies on: TDD, incremental implementation, subagent-driven development, code review, worktrees, security review, database migrations, etc.
2. Map each practice to a specific existing skill.
3. Put the required skill references at the start of the plan, with each skill's absolute filesystem path.
4. If `/incremental-implementation` is included and commits are restricted by default, add the commit authorization instruction.
5. Then describe plan-specific execution details.

If you cannot map a practice to a specific skill, ask the human partner instead of writing a vague concept.
