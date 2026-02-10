# EMP stdlib notes — Option/Result/Error, panics, drops, numeric ops, traits, formatting

This document explains (1) what EMP **already implements today** in this repo, and (2) what it would take to reach a more “Rust-level” standard library experience for the listed primitives.

Scope: Option, Result, Error, panic/assert/unreachable, panic strategy (abort vs unwind), backtraces + source location, drop/destructor integration, safe numeric ops, baseline traits, formatting core, and derive-like helpers.

---

## 1) Option

### What exists today

Implemented in `stdlib/emp_mods/std/option.em` as an `enum`:

```emp
export enum Option {
  None;
  Some(auto);
}
```

Helpers:

- `OptionOps` trait with `isSome()` / `isNone()` implemented for `Option`
- Free functions `isSome(o: Option) -> bool` and `isNone(o: Option) -> bool`

### How you use it (today)

Because the payload type is `auto` (until generics exist), you typically *pattern match* to extract the payload:

```emp
use {Option} from std.option;

fn main() {
  let v: Option = Option::Some(123);

  match v {
    Option::Some(x) => {
      // x has inferred type from the payload
      x;
      return;
    }
    Option::None => {
      return;
    }
  }
}
```

### Important limitations (today)

- No generics: you can’t express `Option[T]` yet.
- Payload is `auto`: it’s flexible, but it also means API design must avoid assuming a fixed payload type.
- No standard “combinator” helpers yet (`map`, `andThen`, `unwrapOr`, etc.). Those can be added once generics land, or in the meantime as ad-hoc helpers for common types.

### What “Rust-level Option” implies

A Rust-like `Option<T>` ecosystem usually includes:

- Total set of combinators: `map`, `mapOr`, `andThen`, `orElse`, `filter`, `zip`, etc.
- `unwrap/expect` (panic-on-None) and `unwrapOr/unwrapOrElse`
- Conversions to/from `Result`
- Iterator integration (optional, depends on whether EMP has iterators)

In EMP, most of those are easiest after **generics** exist.

---

## 2) Result

### What exists today

Implemented in `stdlib/emp_mods/std/result.em`:

```emp
export enum Result {
  Ok(auto);
  Err(auto);
}
```

Helpers:

- `ResultOps` trait with `isOk()` / `isErr()` implemented for `Result`
- Free functions `isOk(r: Result) -> bool` and `isErr(r: Result) -> bool`

### How you use it (today)

Pattern match is the primary tool:

```emp
use {Result} from std.result;

fn div(a: i32, b: i32) -> Result {
  if b == 0 { return Result::Err("divide by zero"); }
  return Result::Ok(a / b);
}

fn main() {
  let r: Result = div(10, 2);
  match r {
    Result::Ok(v) => { v; return; }
    Result::Err(e) => { e; return; }
  }
}
```

### Important limitations (today)

- No generics: cannot express `Result[T, E]`.
- There is no `?` operator / early-return sugar.
- There is no standard error convention yet (string error vs structured error).

### What “Rust-level Result” implies

- Ergonomics: `?`/try operator and `From`-style conversions for error types
- A coherent error story: either “everything implements `Error`” or a clear alternative
- Rich combinators: `map`, `mapErr`, `andThen`, `orElse`, `unwrap`, `expect`, etc.

Again, most of this becomes much nicer once generics exist.

---

## 3) Error

### What exists today

Implemented in `stdlib/emp_mods/core/error.em`.

There is an `Error` trait:

```emp
export trait Error {
  fn message() -> string;
  fn code() -> i64;
  fn hasCause() -> bool;
  fn cause() -> string;
}
```

And a concrete error value `Err`:

- fields: `msg`, `code`, `hasCause`, `causeMsg`
- constructors:
  - `errNew(msg: string) -> Err`
  - `errCode(code: i64, msg: string) -> Err`
  - `errWithCause(msg: string, causeMsg: string) -> Err`
- legacy aliases: `error(...)`, `errorWithCause(...)`

### How you use it (today)

Create an `Err` and return it as a payload in `Result::Err(...)`:

```emp
use {Result} from std.result;
use {Err, errCode} from core.error;

fn openConfig() -> Result {
  // not implemented: fs
  let e: Err = errCode(2, "config file not found");
  return Result::Err(e);
}
```

### What’s missing for a Rust-like error story

Rust’s “nice errors” come from a few things working together:

- A standard `Error` trait (you have the start)
- Formatting (`Display`/`Debug`) for errors
- Source location capture on panic / unwrap / expect
- Optional cause chaining (`source()`) that is *typed*, not only a string
- Conversions between error types (`From`-like) + the `?` operator

To get closer in EMP without generics, a pragmatic next step is:

- Keep `core.error.Err` as the default “stdlib error value”
- Define consistent `code` meanings (or a set of error kinds)
- Add helpers to convert `*u8`/`string` into `Err` consistently

---

## 4) Panic system: panic/assert/debug_assert/unreachable

### What exists today

`core.panic` (`stdlib/emp_mods/core/panic.em`):

- `panic(msg: string)`
- `panic(msg: *u8)`
- `panicCStr(msg: *u8)`
- `unreachable()`

Current behavior is **abort-only**:

- `panicCStr` prints `"panic:"` + the message and then calls `ExitProcess(101)` inside `@emp off`.

`std.assert` (`stdlib/emp_mods/std/assert.em`):

- `assert(cond: bool)`
- `assert(cond: bool, msg: string)`
- `assert(cond: bool, msg: *u8)`

Those route to `core.panic.panicCStr`.

### Mapping to the Rust names in your checklist

EMP does not currently have Rust-style macros like `panic!` / `assert!`.

Instead, the equivalents are **functions**:

- Rust `panic!(...)` → EMP `core.panic.panic(...)`
- Rust `assert!(cond)` → EMP `std.assert.assert(cond)`
- Rust `unreachable!()` → EMP `core.panic.unreachable()`

### `debug_assert`

There is **no** `debug_assert` implementation in the current stdlib.

To implement it cleanly, EMP needs some notion of “debug vs release” available to EMP code, for example:

- a compiler-provided constant (e.g. `core.build.isDebug: bool`), or
- a compile-time conditional facility, or
- a separate module built only in debug builds.

Without that, `debug_assert` would behave identically to `assert`, which defeats its purpose.

---

## 5) Panic strategy: abort vs unwind

### Abort (what EMP does today)

- On panic, the process exits immediately (`ExitProcess`).
- No stack unwinding happens.
- No destructors/drops are run as part of panicking.

This is simple, small, and predictable (good for early-stage toolchains).

### Unwind (what Rust can do, and what it costs)

Unwinding means:

- Panics propagate up the call stack.
- The runtime runs cleanup (“drops”) for in-scope values as stack frames unwind.
- You can optionally catch a panic boundary (`catch_unwind`) and continue.

To implement unwinding in EMP, you need **compiler + codegen + runtime** work:

- Codegen must emit LLVM IR that supports unwinding:
  - landing pads / `invoke` instead of `call` on potentially-panicking calls
  - a personality function
  - unwind tables + metadata
- The language must define unwind boundaries:
  - Unwinding across FFI is usually forbidden/UB unless explicitly supported.
  - Unwinding through `@emp off` regions needs a clear rule (typically: allowed, but unsafe code must remain valid).
- Drop insertion must integrate with unwinding:
  - today EMP inserts explicit `drop` statements in safe mode
  - with unwinding, you typically need cleanup on exceptional paths too

A pragmatic “Rust-like” policy set is:

- default: abort-on-panic (simple)
- optional: unwind-on-panic (feature flag)
- `catch_unwind` only when unwind is enabled

---

## 6) Backtraces + location info (file/line/col)

### What exists today

- The compiler tracks spans with `line` and `col` (see lexer/parser infrastructure).
- Diagnostics already include file/line/col in compiler output.

### What is missing in the runtime

`core.panic` does not currently:

- capture a panic location (file/line/col)
- capture a backtrace
- symbolicate addresses into function names

### A concrete “Rust-level” plan

A staged approach:

1) **Location-only panic** (low cost)
- Add a compiler builtin that exposes “current location” (file/line/col) to the panic call.
- Or: have the compiler rewrite `panic("msg")` into `panicAt("msg", "file", line, col)`.
- Print the location in `panicCStr`.

2) **Raw backtrace capture** (Windows)
- Capture return addresses (e.g. via `RtlCaptureStackBackTrace`).
- Print addresses as hex.

3) **Symbolication** (optional, higher cost)
- Use DbgHelp (`SymInitialize`, `SymFromAddr`) when available.
- Requires careful DLL loading and a lot of Windows edge-case handling.

Rust splits this along feature lines too (backtrace capture depends on build settings and platform support).

---

## 7) Drop / destructor model integration

### What exists today

EMP has a compiler pass that inserts explicit `drop` statements in safe mode.

From the repo docs:

- Drops are inserted at end-of-scope and before `return`.
- Drops are **not inserted** inside `@emp off` blocks.
- Drops are **not inserted** inside `@emp mm off` regions.

This is the backbone for Rust-like deterministic destruction.

### What “Rust-level” implies

To feel Rust-level, users typically expect:

- drops always happen on normal scope exit
- drops happen even on early returns (already true in safe mode)
- if unwind is supported, drops happen during unwinding

Also, you’ll want a clear story for:

- “drop glue” for composites (structs/enums/lists): drop each owned field/element
- explicit `mem::forget` / `ManuallyDrop`-like escape hatches (unsafe)

---

## 8) Safe numeric ops

### What exists today

`stdlib/emp_mods/math/basic.em` provides:

- `absI32`, `absI64`
- `minI32`, `maxI32`
- `clampI32`, `clampI64`
- `signI32`
- constants `I32Min`, `I32Max`

### What’s missing for Rust-level numeric safety

Rust’s integer APIs typically include:

- checked arithmetic: `checkedAdd/Sub/Mul` returning `Option`
- saturating arithmetic: clamps on overflow
- wrapping arithmetic: modulo arithmetic
- overflowing arithmetic: returns `(value, overflowed)`

To implement these efficiently in a compiler+LLVM world, you usually want LLVM overflow intrinsics (or equivalent lowering).

---

## 9) Baseline traits: Eq/Ord/Hash/Clone/Copy/Debug/Display

### What exists today

- EMP has traits (used by `OptionOps`, `ResultOps`).
- The compiler has internal knowledge of “copy-like” primitive types for drop/move purposes.

### What is missing

There are no canonical stdlib traits named `Eq`, `Ord`, `Hash`, `Debug`, `Display`, nor a uniform “clone vs move vs copy” API.

### What Rust-level implies

A minimum viable set:

- `Eq`: `eq(self, other) -> bool`
- `Ord`: `cmp(self, other) -> i32` or `Ordering`
- `Hash`: `hash(self, &mut Hasher)` + `Hasher`
- `Clone`: `clone(self) -> Self` (or `clone(&self)` depending on move rules)
- `Debug` / `Display`: formatting hooks integrated with the formatting engine

Even if you don’t exactly mirror Rust, you want a single set of traits that collections and formatting can rely on.

---

## 10) Formatting core (fmt engine)

### What exists today

- f-strings exist (`$"...{expr}..."` and `$` raw f-strings); see `docs/14_strings.md`.
- `std.console` can print:
  - C strings (`*u8`) via `write/println`
  - built-in `string` via `writeString/writeLineString`

### What’s missing for Rust-level formatting

Rust’s formatting system is a whole subsystem:

- A formatter that parses format strings, flags, width/precision
- A set of formatting traits (`Display`, `Debug`, etc.)
- A way to write into different sinks (`String` builder, stdout, file)
- Zero-allocation formatting paths when writing to a buffer

In EMP, a practical staged approach is:

1) `fmt::writeLine(format: string, args...)` based on the existing f-string machinery (simple)
2) a structured formatting engine with specifiers (`{:x}`, `{:?}`, width/precision)
3) trait-based formatting hooks

Note: a “real” `format(...) -> String` implies a growable `String` type or a builder + explicit allocation strategy.

---

## 11) Derive-like helpers (optional)

Rust’s `#[derive(...)]` is a compiler feature.

A Rust-level ergonomics story typically needs *some* metaprogramming:

- derives for `Debug`, `Eq`, `Hash`, etc.
- auto-impl generation based on struct fields

In EMP, this could be achieved via:

- compiler-supported derives, or
- a macro system, or
- external codegen tooling that emits `.em` sources

This is optional for “stdlib correctness”, but it matters a lot for productivity.

---

## Appendix: quick reference (current module paths)

- `std.option`: `Option`, `OptionOps`, `isSome/isNone`
- `std.result`: `Result`, `ResultOps`, `isOk/isErr`
- `core.error`: `Error` trait, `Err` struct, `errNew/errCode/errWithCause`
- `core.panic`: `panic`, `panicCStr`, `unreachable` (abort-only)
- `std.assert`: `assert` overloads (abort-only via `core.panic`)
- `math.basic`: `absI32/absI64`, `clampI32/clampI64`, etc.
