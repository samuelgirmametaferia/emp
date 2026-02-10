# EMP Documentation

This is the consolidated documentation set for EMP.

- Start here: **Getting Started** and **CLI**
- Language reference: **Types**, **Control Flow**, **Functions**, **Enums & match**, **Traits & UFCS**
- Safety model: **Ownership & Borrowing**, **@emp off**, **@emp mm off**
- Practical: **Standard Library**, **Examples**, **Testing**

## Learn from real code

Use the interactive docs **Runner** to load any `.em` file in this repo and get a syntax/pass walkthrough:

- [Runner](#__runner__)

## Read online (local)

The docs ship with a small local HTML viewer.

1) Start a static server in the repo root:

```text
py -m http.server 8000
```

If you don’t have `py`, try:

```text
python -m http.server 8000
```

2) Open in a browser:

- http://localhost:8000/docs/viewer/

## Source of truth

This docs set is derived from the **compiler implementation** and the **test suite**:

- Lexer tokens/keywords/literals: `emp_lexer.c` / `emp_lexer.h`
- Grammar: `emp_parser.c` / `emp_parser.h`
- Semantic rules: `emp_typecheck.c`, `emp_borrow.c`, `emp_drop.c`, etc.
- Executable spec: `tests/`

The Markdown files at repo root (like `LANGUAGE.md`, `mm.md`, `STDLIB.md`, `PKG.md`) are useful background, but they are not treated as the authority for syntax.
