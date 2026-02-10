# Examples, Tests, and “Source Tour”

Rather than maintaining a giant static index, the docs viewer includes a **Runner** that can load and explain any `.em` file in this repo.

Open the runner:

- [Runner](#__runner__)

## What the runner does

Given EMP source (either pasted, or loaded from the repo), it produces a best-effort explanation of:

- Which syntax constructs are present (keywords/operators/literals/directives)
- Which compiler passes are relevant (lexing → parsing → typecheck → borrow/drop → codegen)
- What the file is “trying to test” (especially for `*_fail.em` test cases)

This is intentionally a **predictor/annotator** (it doesn’t execute EMP); it’s meant to help you learn syntax by reading real `.em` programs.

## Suggested starting points

- `examples/main.em` and `examples/small.em`
- `tests/lex/tokens_ok.em` (token tour)
- `tests/control/match.em` (match)
- `tests/ll/fstring_ok.em` (f-strings)
- `tests/mm/mm_file_directive_ok.em` (`@emp mm off;`)
