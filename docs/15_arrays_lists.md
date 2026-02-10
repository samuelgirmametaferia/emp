# Arrays & Lists

## Arrays: `T[n]`

- Fixed size
- Contiguous
- $O(1)$ indexing

## Lists: `T[]`

Lists are dynamic, growable sequences.

Operational characteristics:

- $O(1)$ indexing
- Amortized $O(1)$ `push`
- $O(n)$ inserts/removes in the middle

## List operations (method sugar)

EMP provides ergonomic member-call sugar for common operations:

- `xs.len()` / `xs.cap()`
- `xs.push(v)`
- `xs.pop()`
- `xs.reserve(n)`
- `xs.insert(i, v)`
- `xs.remove(i)`
- `xs.enqueue(v)` / `xs.dequeue()`

These are lowered to compiler builtins so user code does not need to call low-level `list_*` helpers directly.

## Freeing lists

Freeing list storage is a manual-memory operation and is gated by `@emp mm off`.
See `tests/ll/list_free_drops_elements_ok.em` for behavior around element drops.
