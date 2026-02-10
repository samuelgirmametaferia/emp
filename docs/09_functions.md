# Functions

## Declaration

```emp
fn add(a: i32, b: i32) -> i32 {
  return a + b;
}
```

## `extern fn`

External declarations have no body:

```emp
extern "C" fn rt_write(fd: i32, buf: *u8, len: usize) -> isize;
```

Calling `extern` is only allowed inside `@emp off { ... }`.

As implemented, `extern` is a modifier on a top-level `fn` item:

- `extern fn name(...) -> T;`
- `extern "ABI" fn name(...) -> T;` (optional ABI string literal)

`extern` functions:

- Have no body (must end with `;`)
- Are implicitly `unsafe` in the parser

Example:

```emp
extern "C" fn puts(*u8 s) -> i32;
```

## `unsafe fn`

EMP supports `unsafe fn` as a marker for functions that require an unsafe context (typically implemented using `@emp off` internally).

## `mm fn` (manual-memory-only)

The parser accepts an `mm` modifier on items:

- `mm fn ...`
- `mm extern fn ...`

This is used by the typechecker to gate “manual memory primitives” so they are only callable inside `@emp mm off` regions.

Example (shape only):

```emp
mm fn arena_alloc(auto n) -> *u8 { return null; }
```

## Overload (as implemented)

EMP has tests for overload resolution. See:

- `tests/ll/method_overload_ok.em`
- `tests/overload_ambiguous_fail.em`
