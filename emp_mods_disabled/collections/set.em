// collections.set
//
// A simple hash set for i32 values, backed by collections.map (i32 -> i32).

use {MapI32I32, MapIterI32I32, mapNew, mapPut, mapContains, mapRemove, mapClear, mapLen, mapCap, mapIsEmpty, mapFree, mapIterNew, mapIterNext} from emp_mods.collections.map;

export struct SetI32 {
  m: MapI32I32;
}

export fn setNew() -> SetI32 {
  let s: SetI32;
  s.m = mapNew();
  return s;
}

export fn setLen(s: SetI32) -> i32 {
  return mapLen(s.m);
}

export fn setCap(s: SetI32) -> i32 {
  return mapCap(s.m);
}

export fn setIsEmpty(s: SetI32) -> bool {
  return mapIsEmpty(s.m);
}

export fn setAdd(s: *SetI32, x: i32) -> bool {
  // Use a dummy value.
  return mapPut(&mut s.m, x, 1);
}

export fn setContains(s: *SetI32, x: i32) -> bool {
  return mapContains(&mut s.m, x);
}

export fn setRemove(s: *SetI32, x: i32) -> bool {
  let out: i32;
  return mapRemove(&mut s.m, x, &mut out);
}

export fn setClear(s: *SetI32) {
  mapClear(&mut s.m);
}

export fn setUnion(a: *SetI32, b: *SetI32) -> SetI32 {
  let out: SetI32 = setNew();

  let itA: MapIterI32I32 = mapIterNew();
  let k: i32;
  let v: i32;
  while mapIterNext(&mut a.m, &mut itA, &mut k, &mut v) {
    let _ignore: bool = setAdd(&mut out, k);
  }

  let itB: MapIterI32I32 = mapIterNew();
  while mapIterNext(&mut b.m, &mut itB, &mut k, &mut v) {
    let _ignore: bool = setAdd(&mut out, k);
  }

  return out;
}

export fn setIntersect(a: *SetI32, b: *SetI32) -> SetI32 {
  let out: SetI32 = setNew();

  let itA: MapIterI32I32 = mapIterNew();
  let k: i32;
  let v: i32;
  while mapIterNext(&mut a.m, &mut itA, &mut k, &mut v) {
    if setContains(b, k) {
      let _ignore: bool = setAdd(&mut out, k);
    }
  }

  return out;
}

export fn setDiff(a: *SetI32, b: *SetI32) -> SetI32 {
  // a \ b
  let out: SetI32 = setNew();

  let itA: MapIterI32I32 = mapIterNew();
  let k: i32;
  let v: i32;
  while mapIterNext(&mut a.m, &mut itA, &mut k, &mut v) {
    if !setContains(b, k) {
      let _ignore: bool = setAdd(&mut out, k);
    }
  }

  return out;
}

export mm fn setFree(s: *SetI32) {
  mapFree(&mut s.m);
}
