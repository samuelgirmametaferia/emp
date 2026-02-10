# Status & Roadmap

EMP is implemented in C and evolves quickly.

## What’s solid (covered by tests)

- Ownership/borrow checks (lexical)
- Drop insertion
- `@emp off` and boundary rules
- `@emp mm off` region/file forms and gating of manual primitives
- Enums + `match` (including exhaustiveness/duplicate-arm checks)
- Traits/UFCS (current feature set validated by tests)
- Deterministic module resolution behavior (module tests)

## In progress

- f-string runtime interpolation
- More complete stdlib surface and ergonomic wrappers

## Tracking inconsistencies

See ../INCONSISTENCIES.md.
