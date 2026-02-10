// std.alloc
//
// Tiny ergonomic wrappers around `std.rawmem`.
// Naming is intentionally EMP-ish (short, explicit) and keeps allocation visible.

use {malloc, free, realloc} from std.rawmem;

export mm fn allocBytes(n: usize) -> *u8 {
  return malloc(n);
}

export mm fn reallocBytes(p: *u8, n: usize) -> *u8 {
  return realloc(p, n);
}

export mm fn freeBytes(p: *u8) {
  free(p);
}
