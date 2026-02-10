# Overview

EMP is a compiled systems language with:

- A Rust-like compile-time ownership and borrowing model (safe-by-default)
- Deterministic destruction via compiler-inserted `drop` statements
- An explicit unsafe escape hatch: `@emp off { ... }`
- A stronger manual memory region mode: `@emp mm off;` and `@emp mm off { ... }`
- A deterministic module system (`use ... from ...`) and a bundled stdlib
- LLVM IR code generation through LLVM-C

## Two programming modes

1) **Safe EMP (default)**

- Ownership and borrowing rules are enforced
- Automatic drop insertion runs
- Raw allocation/free primitives are not available

2) **Manual memory mode (`@emp mm off`)**

- Ownership/borrowing/drop insertion are disabled in the region
- Manual memory primitives become legal to call
- Use `defer { ... }` for scoped cleanup

## A minimal example

```emp
fn main() {
  let xs: i32[] = [];
  xs.push(1);
  xs.push(2);

  if xs.len() == 2 {
    return;
  }
}
```

## Where to look in the repo

- Compiler entry point: ../main.c
- Language draft: ../LANGUAGE.md
- Tests: ../tests/
- Examples: ../examples/
- Bundled stdlib modules: ../stdlib/emp_mods/
