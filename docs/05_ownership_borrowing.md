# Ownership & Borrowing

EMP’s default mode is a Rust-like safety model enforced at compile time.

## Ownership

- Values have a single owner.
- Ownership moves by default.
- After a move, the old binding cannot be used.

## Borrowing

- Shared borrow: `&expr` (read-only)
- Mutable borrow: `&mut expr` (exclusive)

Rule:

- $N$ shared borrows OR $1$ mutable borrow, never both.

## Lifetimes

- Lifetimes are inferred.
- Current borrow checking is primarily lexical-scope based.

## Drop insertion

In safe mode, EMP inserts explicit drops so destruction is deterministic:

- End of scope
- Before `return`

Drops are not inserted in `@emp off` blocks.

Manual memory mode (`@emp mm off`) also disables drop insertion in the region (and can disable it for the whole module if applied file-wide).
