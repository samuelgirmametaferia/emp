// std.mem
//
// Thin wrappers around raw memory operations.
// Manual-MM only: these are `mm`-gated.

use {memcpy, memmove, memset} from std.rawmem;

export mm fn copy(dst: *u8, src: *u8, n: usize) {
  memcpy(dst, src, n);
}

export mm fn move(dst: *u8, src: *u8, n: usize) {
  memmove(dst, src, n);
}

export mm fn set(dst: *u8, value: i32, n: usize) {
  memset(dst, value, n);
}
