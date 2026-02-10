# FFI & ABI

## `extern fn`

EMP declares FFI functions with `extern fn` (optionally with an ABI string):

```emp
extern "C" fn rt_write(fd: i32, buf: *u8, len: usize) -> isize;
```

Calling an `extern` function is only permitted inside `@emp off { ... }`.

## ABI surface

See ../ABI.md for the locked-down ABI rules EMP uses (sizes/alignments/layouts) and how they map to LLVM IR.
