# Testing

EMP’s tests are small `.em` programs under `tests/`.

## Naming convention

- `*_ok.em` must compile with exit code 0
- `*_fail.em` must produce diagnostics and exit code 1

## Suites

- `tests/lex/` runs lexer-only via `--lex`
- `tests/ll/` runs LLVM lowering via `--ll --nobin`
- Most other tests run parse+semantics via `--ast`

## Running

```text
powershell -ExecutionPolicy Bypass -File .\tests\run_tests.ps1
```

See ../tests/README.md.
