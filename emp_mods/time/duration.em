// time.duration
//
// Minimal Duration type.
//
// This module is intentionally pure (no OS calls). It provides a consistent,
// normalized representation and basic arithmetic helpers.

// Invariant (for well-formed values):
// - secs >= 0
// - 0 <= nanos < NANOS_PER_SEC
export struct Duration {
  secs: i64;
  nanos: i64;
}

export trait DurationOps {
  fn asSecs() -> i64;
  fn asMillis() -> i64;
  fn asNanos() -> i64;
}

impl DurationOps for Duration {
  fn asSecs() -> i64 {
    return asSecs(self);
  }

  fn asMillis() -> i64 {
    return asMillis(self);
  }

  fn asNanos() -> i64 {
    return asNanos(self);
  }
}

export fn zero() -> Duration {
  let d: Duration;
  d.secs = 0;
  d.nanos = 0;
  return d;
}

export fn fromSecs(secs: i64) -> Duration {
  Duration out = zero();
  @emp off {
    if secs > 0 {
      out.secs = secs;
      out.nanos = 0;
    }
  }
  return out;
}

export fn fromMillis(ms: i64) -> Duration {
  Duration out = zero();
  @emp off {
    if ms > 0 {
      out.secs = ms / 1000;
      out.nanos = (ms % 1000) * 1000000;
    }
  }
  return out;
}

export fn fromNanos(ns: i64) -> Duration {
  Duration out = zero();
  @emp off {
    if ns > 0 {
      out.secs = ns / 1000000000;
      out.nanos = ns % 1000000000;
    }
  }
  return out;
}

export fn asSecs(d: Duration) -> i64 {
  i64 out = 0;
  @emp off {
    out = d.secs;
  }
  return out;
}

export fn asMillis(d: Duration) -> i64 {
  i64 out = 0;
  @emp off {
    out = d.secs * 1000 + (d.nanos / 1000000);
  }
  return out;
}

export fn asNanos(d: Duration) -> i64 {
  i64 out = 0;
  @emp off {
    out = d.secs * 1000000000 + d.nanos;
  }
  return out;
}

export fn add(a: Duration, b: Duration) -> Duration {
  Duration out = zero();
  @emp off {
    out.secs = a.secs + b.secs;
    out.nanos = a.nanos + b.nanos;
    if out.nanos >= 1000000000 {
      out.secs = out.secs + 1;
      out.nanos = out.nanos - 1000000000;
    }
  }
  return out;
}

// Saturating subtraction (never returns a negative duration).
export fn sub(a: Duration, b: Duration) -> Duration {
  Duration out = zero();
  @emp off {
    if a.secs < b.secs {
      // leave `out` as zero
    } else {
      out.secs = a.secs - b.secs;
      out.nanos = a.nanos - b.nanos;
      if out.nanos < 0 {
        if out.secs == 0 {
          out.secs = 0;
          out.nanos = 0;
        } else {
          out.secs = out.secs - 1;
          out.nanos = out.nanos + 1000000000;
        }
      }
    }
  }
  return out;
}
