# Manual memory mode: `@emp mm off`

Manual memory mode is EMP’s “Zig-level” region-based mode.

## Syntax

File-wide:

```emp
@emp mm off;
```

Block-scoped:

```emp
@emp mm off {
  // ...
}
```

## Meaning

Inside an MM-off region:

- Ownership and borrow checking are disabled
- Automatic drop insertion is disabled
- Manual memory primitives are allowed (alloc/free, pointer ops, etc.)

Outside MM-off:

- Manual memory primitives are rejected
- Safe mode rules apply

## Cleanup pattern

Use `defer { ... }` for scoped cleanup when drops are disabled.

See ../mm.md for the detailed spec.
