// collections.vec
//
// A small typed Vec for i32 built on EMP's built-in list type.
// Allocation is managed by the compiler/runtime list implementation.
// Manual-MM is required only to explicitly free backing storage.

use {Option} from std.option;

export struct VecI32 {
  data: i32[];
}

export fn vecNew() -> VecI32 {
  let v: VecI32;
  v.data = [];
  return v;
}

export fn vecWithCapacity(minCap: i32) -> VecI32 {
  let v: VecI32;
  v.data = [];
  list_reserve(&mut v.data, minCap);
  return v;
}

export fn vecLen(v: VecI32) -> i32 {
  return v.data.len();
}

export fn vecCap(v: VecI32) -> i32 {
  return v.data.cap();
}

export fn vecIsEmpty(v: VecI32) -> bool {
  return v.data.len() == 0;
}

export fn vecClear(v: *VecI32) {
  // Pop until empty (keeps capacity).
  while v.data.len() != 0 {
    let _ignore: i32 = v.data.pop();
  }
}

export fn vecResize(v: *VecI32, newLen: i32, fill: i32) {
  let n: i32 = v.data.len();
  if newLen < n {
    while v.data.len() > newLen {
      let _ignore: i32 = v.data.pop();
    }
    return;
  }
  while v.data.len() < newLen {
    v.data.append(fill);
  }
}

export fn vecReserve(v: *VecI32, additional: i32) {
  // Reserve capacity for at least `additional` more elements.
  // Uses the compiler builtin list reserve.
  list_reserve(&mut v.data, v.data.len() + additional);
}

export fn vecExtend(v: *VecI32, other: VecI32) {
  list_reserve(&mut v.data, v.data.len() + other.data.len());
  for i in 0...other.data.len() {
    v.data.append(other.data[i]);
  }
}

export fn vecFill(v: *VecI32, value: i32) {
  for i in 0...v.data.len() {
    v.data[i] = value;
  }
}

export fn vecSwap(v: *VecI32, i: i32, j: i32) {
  if i == j { return; }
  let tmp: i32 = v.data[i];
  v.data[i] = v.data[j];
  v.data[j] = tmp;
}

export fn vecPush(v: *VecI32, x: i32) {
  v.data.push(x);
}

export fn vecAppend(v: *VecI32, x: i32) {
  v.data.append(x);
}

export fn vecPop(v: *VecI32) -> i32 {
  return v.data.pop();
}

export fn vecTryPop(v: *VecI32) -> Option {
  if v.data.len() == 0 {
    return Option::None;
  }
  let x: i32 = v.data.pop();
  return Option::Some(x);
}

export fn vecFront(v: VecI32) -> i32 {
  if v.data.len() == 0 { return 0; }
  return v.data[0];
}

export fn vecBack(v: VecI32) -> i32 {
  let n: i32 = v.data.len();
  if n == 0 { return 0; }
  return v.data[n - 1];
}

export fn vecIndexOf(v: VecI32, x: i32) -> i32 {
  for i in 0...v.data.len() {
    if v.data[i] == x { return i; }
  }
  return -1;
}

export fn vecContains(v: VecI32, x: i32) -> bool {
  return vecIndexOf(v, x) != -1;
}

export fn vecSum(v: VecI32) -> i32 {
  i32 s = 0;
  for i in 0...v.data.len() {
    s = s + v.data[i];
  }
  return s;
}

export fn vecReverse(v: *VecI32) {
  let n: i32 = v.data.len();
  if n <= 1 { return; }
  i32 i = 0;
  i32 j = n - 1;
  while i < j {
    vecSwap(v, i, j);
    i = i + 1;
    j = j - 1;
  }
}

export fn vecSort(v: *VecI32) {
  let n: i32 = v.data.len();
  for i in 1...n {
    let key: i32 = v.data[i];
    i32 j = i - 1;
    while j >= 0 {
      if v.data[j] <= key { break; }
      v.data[j + 1] = v.data[j];
      j = j - 1;
    }
    v.data[j + 1] = key;
  }
}

export fn vecBinarySearch(v: VecI32, x: i32) -> i32 {
  i32 lo = 0;
  i32 hi = v.data.len();
  while lo < hi {
    i32 mid = lo + ((hi - lo) / 2);
    let mv: i32 = v.data[mid];
    if mv == x { return mid; }
    if mv < x { lo = mid + 1; } else { hi = mid; }
  }
  return -1;
}

export fn vecDedupSorted(v: *VecI32) -> i32 {
  let n: i32 = v.data.len();
  if n <= 1 { return n; }
  i32 write = 1;
  for i in 1...n {
    if v.data[i] != v.data[write - 1] {
      v.data[write] = v.data[i];
      write = write + 1;
    }
  }
  while v.data.len() > write {
    let _ignore: i32 = v.data.pop();
  }
  return write;
}

export fn vecGet(v: VecI32, index: i32) -> i32 {
  return v.data[index];
}

export fn vecSet(v: *VecI32, index: i32, x: i32) {
  v.data[index] = x;
}

export fn vecSwapRemove(v: *VecI32, index: i32) -> i32 {
  let n: i32 = v.data.len();
  if n == 0 { return 0; }

  let last: i32 = v.data.pop();
  if index == (n - 1) {
    return last;
  }

  let removed: i32 = v.data[index];
  v.data[index] = last;
  return removed;
}

export fn vecRemoveShift(v: *VecI32, index: i32) -> i32 {
  let n: i32 = v.data.len();
  if n == 0 { return 0; }

  let removed: i32 = v.data[index];

  // Shift elements left.
  for i in index... (n - 1) {
    if i + 1 < n {
      v.data[i] = v.data[i + 1];
    }
  }

  let _ignore: i32 = v.data.pop();
  return removed;
}

export mm fn vecFree(v: *VecI32) {
  // Explicitly release backing memory.
  list_free(&mut v.data);
}

// ---- VecU8 ----

export struct VecU8 {
  data: u8[];
}

export fn vecU8New() -> VecU8 {
  let v: VecU8;
  v.data = [];
  return v;
}

export fn vecU8Len(v: VecU8) -> i32 { return v.data.len(); }
export fn vecU8Cap(v: VecU8) -> i32 { return v.data.cap(); }
export fn vecU8IsEmpty(v: VecU8) -> bool { return v.data.len() == 0; }

export fn vecU8Reserve(v: *VecU8, additional: i32) {
  list_reserve(&mut v.data, v.data.len() + additional);
}

export fn vecU8Push(v: *VecU8, x: u8) { v.data.append(x); }
export fn vecU8Pop(v: *VecU8) -> u8 { return list_pop(&mut v.data); }

export fn vecU8Get(v: VecU8, index: i32) -> u8 { return v.data[index]; }
export fn vecU8Set(v: *VecU8, index: i32, x: u8) { v.data[index] = x; }

export fn vecU8Clear(v: *VecU8) {
  while v.data.len() != 0 {
    let _ignore: u8 = list_pop(&mut v.data);
  }
}

export fn vecU8Reverse(v: *VecU8) {
  let n: i32 = v.data.len();
  if n <= 1 { return; }
  i32 i = 0;
  i32 j = n - 1;
  while i < j {
    let tmp: u8 = v.data[i];
    v.data[i] = v.data[j];
    v.data[j] = tmp;
    i = i + 1;
    j = j - 1;
  }
}

export mm fn vecU8Free(v: *VecU8) {
  list_free(&mut v.data);
}

// ---- VecString ----

export struct VecString {
  data: string[];
}

export fn vecStringNew() -> VecString {
  let v: VecString;
  v.data = [];
  return v;
}

export fn vecStringLen(v: VecString) -> i32 { return v.data.len(); }
export fn vecStringCap(v: VecString) -> i32 { return v.data.cap(); }
export fn vecStringIsEmpty(v: VecString) -> bool { return v.data.len() == 0; }

export fn vecStringReserve(v: *VecString, additional: i32) {
  list_reserve(&mut v.data, v.data.len() + additional);
}

export fn vecStringPush(v: *VecString, x: string) { v.data.append(x); }
export fn vecStringPop(v: *VecString) -> string { return list_pop(&mut v.data); }

export fn vecStringGet(v: VecString, index: i32) -> string { return v.data[index]; }
export fn vecStringSet(v: *VecString, index: i32, x: string) { v.data[index] = x; }

export fn vecStringIndexOf(v: VecString, x: string) -> i32 {
  for i in 0...v.data.len() {
    if v.data[i] == x { return i; }
  }
  return -1;
}

export fn vecStringContains(v: VecString, x: string) -> bool {
  return vecStringIndexOf(v, x) != -1;
}

export fn vecStringClear(v: *VecString) {
  while v.data.len() != 0 {
    let _ignore: string = list_pop(&mut v.data);
  }
}

export mm fn vecStringFree(v: *VecString) {
  list_free(&mut v.data);
}
