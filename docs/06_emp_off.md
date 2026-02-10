# Unsafe blocks: `@emp off`

`@emp off { ... }` is an explicit unsafe escape hatch.

Inside the block:

- Ownership/borrow/lifetime checks are disabled.

The compiler still enforces boundary rules so unsafe actions do not “leak” invalid states back into safe code.

## Typical uses

- FFI calls to `extern fn`
- Very low-level operations that must be locally unsafely expressed

## Not the same as manual memory mode

`@emp off` does **not** grant access to manual allocation/free primitives. Those are gated by `@emp mm off`.
