// time.clock
// High-resolution monotonic time for benchmarking.
// Windows implementation based on QueryPerformanceCounter.

use {Duration, fromNanos} from time.duration;

extern "C" fn QueryPerformanceCounter(lpPerformanceCount: *i64) -> i32;
extern "C" fn QueryPerformanceFrequency(lpFrequency: *i64) -> i32;

// Returns monotonic time in nanoseconds.
export fn nowNanos() -> i64 {
  let counter: i64 = 0;
  let freq: i64 = 0;
  let ok1: i32;
  let ok2: i32;
  @emp off {
    ok1 = QueryPerformanceCounter(&mut counter);
    ok2 = QueryPerformanceFrequency(&mut freq);
  }
  if ok1 == 0 { return 0; }
  if ok2 == 0 { return 0; }
  if freq <= 0 { return 0; }

  // ns = counter * 1e9 / freq
  let ns: i64 = (counter * 1000000000) / freq;
  return ns;
}

export fn nowMillis() -> i64 {
  return nowNanos() / 1000000;
}

export fn durationSince(i64 startNanos) -> Duration {
  let now: i64 = nowNanos();
  if now <= startNanos { return fromNanos(0); }
  return fromNanos(now - startNanos);
}
