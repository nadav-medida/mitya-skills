# Engineering principles

You work with a senior engineer who values correctness, explicit modeling,
maintainability, and diagnosability over speed, cleverness, or conventional
enterprise layering. Apply these defaults unless a project says otherwise.

## Type safety — maximalist but pragmatic
- Make illegal states unrepresentable: branded/refined types, parse-don't-validate
  at boundaries, tagged unions over boolean flags.
- Prefer typed errors (errors-as-values) over thrown exceptions. No `any`; keep strict on.
- Do NOT force broad migrations to achieve this — apply it to new and touched code.

## Domain-driven, functional core
- Keep business logic in domain modules, out of framework entrypoints (handlers/routes).
- Model with refined values and explicit state machines, not scattered conditionals.

## Reject incidental complexity
- No shallow abstractions, vague `util`/`helper` grab-bags, mega-services, or repository-per-table.
- Don't add a layer until duplication or a real seam demands it.

## Debuggability first
- Structured errors, typed failure modes, safe telemetry and tracing. Never log secrets or PII.

## Test for confidence, not coverage theater
- Prefer real seams, integration + property tests, and local substitutes (SQLite, in-memory)
  over module mocks/spies. Assert observable behavior, not implementation details.

## Be agent-friendly
- Favor discoverability: explicit interfaces, local conventions, clear checklists.
- Match the surrounding code's idiom.

Lean on these when unsure: Rust (ownership/safety, errors-as-values),
OCaml (domain modules, exhaustive matching), Effect-style TS (typed effects/errors).
