// collections.queue
//
// A small queue for i32 built on EMP's built-in list type.
// Uses list enqueue/dequeue semantics.

use {Option} from std.option;

export struct QueueI32 {
  data: i32[];
}

export fn queueNew() -> QueueI32 {
  let q: QueueI32;
  q.data = [];
  return q;
}

export fn queueLen(q: QueueI32) -> i32 {
  return q.data.len();
}

export fn queueCap(q: QueueI32) -> i32 {
  return q.data.cap();
}

export fn queueIsEmpty(q: QueueI32) -> bool {
  return q.data.len() == 0;
}

export fn queueReserve(q: *QueueI32, additional: i32) {
  list_reserve(&mut q.data, q.data.len() + additional);
}

export fn queueEnqueue(q: *QueueI32, x: i32) {
  q.data.enqueue(x);
}

export fn queueDequeue(q: *QueueI32) -> i32 {
  return q.data.dequeue();
}

export fn queueTryDequeue(q: *QueueI32) -> Option {
  if q.data.len() == 0 {
    return Option::None;
  }
  let x: i32 = q.data.dequeue();
  return Option::Some(x);
}

export fn queuePeek(q: QueueI32) -> i32 {
  if q.data.len() == 0 { return 0; }
  return q.data[0];
}

export fn queuePeekBack(q: QueueI32) -> i32 {
  let n: i32 = q.data.len();
  if n == 0 { return 0; }
  return q.data[n - 1];
}

export fn queueEnqueueMany(q: *QueueI32, xs: i32[]) {
  list_reserve(&mut q.data, q.data.len() + xs.len());
  for i in 0...xs.len() {
    q.data.enqueue(xs[i]);
  }
}

export fn queueDrainToList(q: *QueueI32) -> i32[] {
  let out: i32[] = [];
  list_reserve(&mut out, q.data.len());
  while q.data.len() != 0 {
    out.append(q.data.dequeue());
  }
  return out;
}

export fn queueClear(q: *QueueI32) {
  while q.data.len() != 0 {
    let _ignore: i32 = q.data.dequeue();
  }
}

export mm fn queueFree(q: *QueueI32) {
  list_free(&mut q.data);
}
