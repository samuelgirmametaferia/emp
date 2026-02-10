# Standard Library

EMP ships a bundled stdlib under `stdlib/emp_mods/*`.

## Today’s bundled modules

Look under `stdlib/emp_mods/` for the current set. In this repo snapshot, it includes:

- `std/*` (assert/console/option/result/mm/rawmem/mem/alloc)
- `alloc/arena` (arena allocator)
- `io/console`
- `math/basic`
- `time/duration`

## Policy: explicit allocation

Allocation primitives are only callable inside `@emp mm off` regions.

See ../STDLIB.md for the full checklist and design principles.
