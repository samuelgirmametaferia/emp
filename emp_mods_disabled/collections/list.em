// collections.list
//
// Utilities around EMP's built-in list type.
//
// This module intentionally exposes camelCase helpers (no underscores)
// while delegating to compiler-provided list operations internally.

use {Option} from std.option;

// ---- Core metadata ----

export fn lenI32(xs: i32[]) -> i32 { return xs.len(); }
export fn capI32(xs: i32[]) -> i32 { return xs.cap(); }
export fn isEmptyI32(xs: i32[]) -> bool { return xs.len() == 0; }

export fn firstI32(xs: i32[]) -> i32 {
  if xs.len() == 0 { return 0; }
  return xs[0];
}

export fn lastI32(xs: i32[]) -> i32 {
  let n: i32 = xs.len();
  if n == 0 { return 0; }
  return xs[n - 1];
}

// ---- Mutation ----

export fn reserveI32(xs: *i32[], minCap: i32) {
  list_reserve(xs, minCap);
}

export fn resizeI32(xs: *i32[], newLen: i32, fill: i32) {
  let n: i32 = xs.len();
  if newLen < n {
    while xs.len() > newLen {
      let _ignore: i32 = list_pop(xs);
    }
    return;
  }
  while xs.len() < newLen {
    xs.append(fill);
  }
}

export fn pushI32(xs: *i32[], x: i32) {
  list_push(xs, x);
}

export fn appendI32(xs: *i32[], x: i32) {
  xs.append(x);
}

export fn enqueueI32(xs: *i32[], x: i32) {
  xs.enqueue(x);
}

export fn popI32(xs: *i32[]) -> i32 {
  return list_pop(xs);
}

export fn dequeueI32(xs: *i32[]) -> i32 {
  return xs.dequeue();
}

export fn tryPopI32(xs: *i32[]) -> Option {
  if xs.len() == 0 { return Option::None; }
  return Option::Some(list_pop(xs));
}

export fn clearI32(xs: *i32[]) {
  while xs.len() != 0 {
    let _ignore: i32 = list_pop(xs);
  }
}

export fn swapRemoveI32(xs: *i32[], index: i32) -> i32 {
  let n: i32 = xs.len();
  if n == 0 { return 0; }

  let last: i32 = list_pop(xs);
  if index == (n - 1) { return last; }

  let removed: i32 = xs[index];
  xs[index] = last;
  return removed;
}

export fn insertI32(xs: *i32[], index: i32, x: i32) {
  let n: i32 = xs.len();
  if index >= n {
    xs.append(x);
    return;
  }

  // Grow by one.
  xs.append(0);

  // Shift elements right.
  let i: i32 = n;
  while i > index {
    xs[i] = xs[i - 1];
    i = i - 1;
  }
  xs[index] = x;
}

export fn extendI32(dst: *i32[], src: i32[]) {
  list_reserve(dst, dst.len() + src.len());
  for i in 0...src.len() {
    dst.append(src[i]);
  }
}

export fn fillI32(xs: *i32[], value: i32) {
  for i in 0...xs.len() {
    xs[i] = value;
  }
}

export fn swapI32(xs: *i32[], i: i32, j: i32) {
  if i == j { return; }
  let tmp: i32 = xs[i];
  xs[i] = xs[j];
  xs[j] = tmp;
}

export fn equalsI32(a: i32[], b: i32[]) -> bool {
  if a.len() != b.len() { return false; }
  for i in 0...a.len() {
    if a[i] != b[i] { return false; }
  }
  return true;
}

export fn countI32(xs: i32[], x: i32) -> i32 {
  i32 c = 0;
  for i in 0...xs.len() {
    if xs[i] == x { c = c + 1; }
  }
  return c;
}

export fn removeShiftI32(xs: *i32[], index: i32) -> i32 {
  let n: i32 = xs.len();
  if n == 0 { return 0; }

  let removed: i32 = xs[index];

  for i in index...(n - 1) {
    if i + 1 < n {
      xs[i] = xs[i + 1];
    }
  }

  let _ignore: i32 = list_pop(xs);
  return removed;
}

// ---- Queries ----

export fn containsI32(xs: i32[], x: i32) -> bool {
  for i in 0...xs.len() {
    if xs[i] == x { return true; }
  }
  return false;
}

export fn minI32(xs: i32[]) -> i32 {
  let n: i32 = xs.len();
  if n == 0 { return 0; }
  i32 m = xs[0];
  for i in 1...n {
    if xs[i] < m { m = xs[i]; }
  }
  return m;
}

export fn maxI32(xs: i32[]) -> i32 {
  let n: i32 = xs.len();
  if n == 0 { return 0; }
  i32 m = xs[0];
  for i in 1...n {
    if xs[i] > m { m = xs[i]; }
  }
  return m;
}

export fn binarySearchI32(xs: i32[], x: i32) -> i32 {
  // Returns index if found, else -1. Assumes sorted ascending.
  i32 lo = 0;
  i32 hi = xs.len();
  while lo < hi {
    i32 mid = lo + ((hi - lo) / 2);
    let v: i32 = xs[mid];
    if v == x { return mid; }
    if v < x {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return -1;
}

export fn sortI32(xs: *i32[]) {
  // Simple in-place insertion sort (good enough for small lists).
  let n: i32 = xs.len();
  for i in 1...n {
    let key: i32 = xs[i];
    i32 j = i - 1;
    while j >= 0 {
      if xs[j] <= key { break; }
      xs[j + 1] = xs[j];
      j = j - 1;
    }
    xs[j + 1] = key;
  }
}

export fn dedupSortedI32(xs: *i32[]) -> i32 {
  // Removes adjacent duplicates from a sorted list. Returns new length.
  let n: i32 = xs.len();
  if n <= 1 { return n; }
  i32 write = 1;
  for i in 1...n {
    if xs[i] != xs[write - 1] {
      xs[write] = xs[i];
      write = write + 1;
    }
  }
  while xs.len() > write {
    let _ignore: i32 = list_pop(xs);
  }
  return write;
}

export fn indexOfI32(xs: i32[], x: i32) -> i32 {
  for i in 0...xs.len() {
    if xs[i] == x { return i; }
  }
  return -1;
}

export fn sumI32(xs: i32[]) -> i32 {
  i32 s = 0;
  for i in 0...xs.len() {
    s = s + xs[i];
  }
  return s;
}

export fn reverseI32(xs: *i32[]) {
  let n: i32 = xs.len();
  if n <= 1 { return; }

  i32 i = 0;
  i32 j = n - 1;
  while i < j {
    let tmp: i32 = xs[i];
    xs[i] = xs[j];
    xs[j] = tmp;
    i = i + 1;
    j = j - 1;
  }
}

// ---- u8 helpers ----

export fn lenU8(xs: u8[]) -> i32 { return xs.len(); }
export fn isEmptyU8(xs: u8[]) -> bool { return xs.len() == 0; }

export fn pushU8(xs: *u8[], x: u8) { xs.append(x); }

export fn popU8(xs: *u8[]) -> u8 {
  return list_pop(xs);
}

export fn tryPopU8(xs: *u8[]) -> Option {
  if xs.len() == 0 { return Option::None; }
  return Option::Some(list_pop(xs));
}

export fn containsU8(xs: u8[], x: u8) -> bool {
  for i in 0...xs.len() {
    if xs[i] == x { return true; }
  }
  return false;
}

export fn reverseU8(xs: *u8[]) {
  let n: i32 = xs.len();
  if n <= 1 { return; }
  i32 i = 0;
  i32 j = n - 1;
  while i < j {
    let tmp: u8 = xs[i];
    xs[i] = xs[j];
    xs[j] = tmp;
    i = i + 1;
    j = j - 1;
  }
}

export mm fn freeU8(xs: *u8[]) {
  list_free(xs);
}

// ---- string helpers ----

export fn lenString(xs: string[]) -> i32 { return xs.len(); }
export fn isEmptyString(xs: string[]) -> bool { return xs.len() == 0; }

export fn pushString(xs: *string[], x: string) { xs.append(x); }

export fn popString(xs: *string[]) -> string {
  return list_pop(xs);
}

export fn tryPopString(xs: *string[]) -> Option {
  if xs.len() == 0 { return Option::None; }
  return Option::Some(list_pop(xs));
}

export fn containsString(xs: string[], x: string) -> bool {
  for i in 0...xs.len() {
    if xs[i] == x { return true; }
  }
  return false;
}

export mm fn freeString(xs: *string[]) {
  list_free(xs);
}

// ---- Manual memory release ----

export mm fn freeI32(xs: *i32[]) {
  list_free(xs);
}
