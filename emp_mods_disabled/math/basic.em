// Pure helpers. Keep this module allocation-free and side-effect-free.

export const I32Min: i32 = -2147483648;
export const I32Max: i32 = 2147483647;

export fn absI32(x: i32) -> i32 {
  if x < 0 {
    return -x;
  }
  return x;
}

export fn clampI32(x: i32, lo: i32, hi: i32) -> i32 {
  if x < lo { return lo; }
  if x > hi { return hi; }
  return x;
}
