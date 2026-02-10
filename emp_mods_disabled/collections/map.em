// collections.map
//
// A simple open-addressing hash map for i32 -> i32.
//
// Notes:
// - Uses parallel built-in lists for storage.
// - Requires explicit `mapFree` to release memory (mm-gated).
// - Capacity is maintained as a power of two.

use {Option} from std.option;

fn isPow2(x: i32) -> bool {
  if x <= 0 { return false; }
  return (x & (x - 1)) == 0;
}

fn nextPow2(minCap: i32) -> i32 {
  i32 cap = 1;
  while cap < minCap {
    cap = cap * 2;
  }
  return cap;
}

fn hashI32(k: i32) -> i32 {
  // A small integer mix (xorshift + multiply).
  i32 x = k;
  x = x ^ (x >> 16);
  x = x * 747796405;
  x = x ^ (x >> 16);
  return x;
}

export struct MapI32I32 {
  keys: i32[];
  vals: i32[];
  states: u8[]; // 0=empty, 1=full, 2=tomb
  len: i32;
}

export fn mapNew() -> MapI32I32 {
  return mapWithCapacity(8);
}

export fn mapWithCapacity(minCap: i32) -> MapI32I32 {
  let m: MapI32I32;
  m.keys = [];
  m.vals = [];
  m.states = [];
  m.len = 0;

  i32 cap = nextPow2(minCap);
  if cap < 8 { cap = 8; }

  // Materialize arrays to length == cap.
  list_reserve(&mut m.keys, cap);
  list_reserve(&mut m.vals, cap);
  list_reserve(&mut m.states, cap);

  for i in 0...cap {
    m.keys.append(0);
    m.vals.append(0);
    m.states.append(0);
  }

  return m;
}

export fn mapLen(m: MapI32I32) -> i32 {
  return m.len;
}

export fn mapCap(m: MapI32I32) -> i32 {
  return m.keys.len();
}

export fn mapIsEmpty(m: MapI32I32) -> bool {
  return m.len == 0;
}

export fn mapLoadFactorPermille(m: MapI32I32) -> i32 {
  let cap: i32 = m.keys.len();
  if cap == 0 { return 0; }
  // permille = len / cap * 1000
  return (m.len * 1000) / cap;
}

fn mapFindSlot(m: *MapI32I32, key: i32, wantInsert: bool, found: *bool) -> i32 {
  i32 cap = m.keys.len();
  if cap == 0 { *found = false; return -1; }

  // Ensure power-of-two capacity for mask-based indexing.
  if !isPow2(cap) { *found = false; return -1; }

  i32 mask = cap - 1;
  i32 start = hashI32(key) & mask;
  i32 firstTomb = -1;

  for step in 0...cap {
    i32 i = (start + step) & mask;
    u8 st = m.states[i];

    if st == 0 {
      // Empty slot.
      if wantInsert {
        if firstTomb != -1 {
          *found = false;
          return firstTomb;
        }
        *found = false;
        return i;
      }
      *found = false;
      return -1;
    }

    if st == 2 {
      if wantInsert && firstTomb == -1 { firstTomb = i; }
      continue;
    }

    // Full.
    if m.keys[i] == key {
      *found = true;
      return i;
    }
  }

  *found = false;
  if wantInsert && firstTomb != -1 { return firstTomb; }
  return -1;
}

fn mapRehash(m: *MapI32I32, newCap: i32) {
  let oldKeys: i32[] = m.keys;
  let oldVals: i32[] = m.vals;
  let oldStates: u8[] = m.states;
  i32 oldCap = oldKeys.len();

  let fresh: MapI32I32 = mapWithCapacity(newCap);

  m.keys = fresh.keys;
  m.vals = fresh.vals;
  m.states = fresh.states;
  m.len = 0;

  for i in 0...oldCap {
    if oldStates[i] == 1 {
      let k: i32 = oldKeys[i];
      let v: i32 = oldVals[i];
      let _ignore: bool = mapPut(m, k, v);
    }
  }

  // Free old backing storage.
  @emp mm off {
    list_free(&mut oldKeys);
    list_free(&mut oldVals);
    list_free(&mut oldStates);
  }
}

export fn mapPut(m: *MapI32I32, key: i32, value: i32) -> bool {
  i32 cap = m.keys.len();
  if cap == 0 {
    let fresh: MapI32I32 = mapWithCapacity(8);
    m.keys = fresh.keys;
    m.vals = fresh.vals;
    m.states = fresh.states;
    m.len = 0;
    cap = m.keys.len();
  }

  // Grow when load factor exceeds ~0.7.
  if ((m.len + 1) * 10) > (cap * 7) {
    mapRehash(m, cap * 2);
    cap = m.keys.len();
  }

  let f: bool;
  i32 slot = mapFindSlot(m, key, true, &mut f);
  if slot < 0 { return false; }

  if f {
    // Update existing.
    m.vals[slot] = value;
    return false;
  }

  // Insert new.
  m.keys[slot] = key;
  m.vals[slot] = value;
  m.states[slot] = 1;
  m.len = m.len + 1;
  return true;
}

export fn mapGet(m: *MapI32I32, key: i32, out: *i32) -> bool {
  let f: bool;
  i32 slot = mapFindSlot(m, key, false, &mut f);
  if !f { return false; }
  *out = m.vals[slot];
  return true;
}

export fn mapTryGet(m: *MapI32I32, key: i32) -> Option {
  return mapGetOption(m, key);
}

export fn mapGetOr(m: *MapI32I32, key: i32, fallback: i32) -> i32 {
  let out: i32;
  if mapGet(m, key, &mut out) { return out; }
  return fallback;
}

export fn mapGetOrPut(m: *MapI32I32, key: i32, valueIfMissing: i32) -> i32 {
  let out: i32;
  if mapGet(m, key, &mut out) { return out; }
  let _ins: bool = mapPut(m, key, valueIfMissing);
  return valueIfMissing;
}

export fn mapUpdate(m: *MapI32I32, key: i32, newValue: i32) -> bool {
  let f: bool;
  i32 slot = mapFindSlot(m, key, false, &mut f);
  if !f { return false; }
  m.vals[slot] = newValue;
  return true;
}

export fn mapGetOption(m: *MapI32I32, key: i32) -> Option {
  let f: bool;
  i32 slot = mapFindSlot(m, key, false, &mut f);
  if !f { return Option::None; }
  return Option::Some(m.vals[slot]);
}

export fn mapContains(m: *MapI32I32, key: i32) -> bool {
  let f: bool;
  let _slot: i32 = mapFindSlot(m, key, false, &mut f);
  return f;
}

export fn mapRemoveKey(m: *MapI32I32, key: i32) -> bool {
  let out: i32;
  return mapRemove(m, key, &mut out);
}

export fn mapRemove(m: *MapI32I32, key: i32, out: *i32) -> bool {
  let f: bool;
  i32 slot = mapFindSlot(m, key, false, &mut f);
  if !f { return false; }

  *out = m.vals[slot];
  m.states[slot] = 2;
  m.len = m.len - 1;
  return true;
}

export fn mapClear(m: *MapI32I32) {
  i32 cap = m.keys.len();
  for i in 0...cap {
    m.states[i] = 0;
  }
  m.len = 0;
}

export struct MapIterI32I32 {
  idx: i32;
}

export fn mapIterNew() -> MapIterI32I32 {
  let it: MapIterI32I32;
  it.idx = 0;
  return it;
}

export fn mapIterNext(m: *MapI32I32, it: *MapIterI32I32, outKey: *i32, outVal: *i32) -> bool {
  i32 cap = m.keys.len();
  while it.idx < cap {
    i32 i = it.idx;
    it.idx = it.idx + 1;
    if m.states[i] == 1 {
      *outKey = m.keys[i];
      *outVal = m.vals[i];
      return true;
    }
  }
  return false;
}

export fn mapKeys(m: *MapI32I32) -> i32[] {
  let xs: i32[] = [];
  list_reserve(&mut xs, m.len);

  let it: MapIterI32I32 = mapIterNew();
  let k: i32;
  let v: i32;
  while mapIterNext(m, &mut it, &mut k, &mut v) {
    xs.append(k);
  }
  return xs;
}

export fn mapValues(m: *MapI32I32) -> i32[] {
  let xs: i32[] = [];
  list_reserve(&mut xs, m.len);

  let it: MapIterI32I32 = mapIterNew();
  let k: i32;
  let v: i32;
  while mapIterNext(m, &mut it, &mut k, &mut v) {
    xs.append(v);
  }
  return xs;
}

export mm fn mapFree(m: *MapI32I32) {
  list_free(&mut m.keys);
  list_free(&mut m.vals);
  list_free(&mut m.states);
  m.len = 0;
}
