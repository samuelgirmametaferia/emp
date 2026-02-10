// std.rawmem
//
// Manual memory primitives.
//
// All exports in this module are `mm`-gated: they can only be called inside
// `@emp mm off { ... }` (or in a file with `@emp mm off;`).

// C runtime allocation
export mm extern "C" fn malloc(size: usize) -> *u8;
export mm extern "C" fn free(p: *u8);
export mm extern "C" fn realloc(p: *u8, size: usize) -> *u8;

// C runtime memory ops
export mm extern "C" fn memcpy(dst: *u8, src: *u8, n: usize) -> *u8;
export mm extern "C" fn memmove(dst: *u8, src: *u8, n: usize) -> *u8;
export mm extern "C" fn memset(dst: *u8, value: i32, n: usize) -> *u8;
