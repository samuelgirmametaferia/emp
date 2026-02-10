# Parallel Backend Lowering (DAG → LLVM IR)

This document designs the **compiler backend** for lowering EMP’s concurrency surface:

- `@emp parallel { ... }`
- `parfor i in iterable { ... }`
- `stmtA ~> stmtB ~> ...;` dependency chains
- reductions (`reduce.*` expr form + block-form reductions over `parfor`)

…into **LLVM IR** in a **performance-aware** and **Rust-level safe** way.

It is intended to be consistent with the language-level spec in `docs/multithreading.md`.

## 0. Design constraints (non-negotiables)

1. **Determinism by default**
   - Unordered conflicting writes/reads to shared mutable state are compile-time errors.
   - `@nondeterministic` is an explicit escape hatch.

2. **Rust-level safety**
   - No data races.
   - No use-before-ready (temporal correctness) across tasks.

3. **One execution model**
   - All concurrency lowers to a single **task DAG** representation.

4. **Performance-aware lowering**
   - Fuse tiny tasks.
   - Avoid unnecessary barriers.
   - Use chunked work-stealing for loops.
   - Enable vectorization + prefetch where safe.

---

## 1. Pipeline overview

The backend is structured as 3 layers:

### 1.1 Frontend / semantic validation (compile-time)

Input: typed AST

Responsibilities:
- Identify parallel regions and structured parallel loops.
- Build a **DAG model** of tasks + dependencies.
- Perform legality checks:
  - Shared mutable writes must be **explicitly ordered** or performed via **reduction** or **atomic**.
  - Detect cycles.
  - Enforce temporal correctness: any use of a task-produced value must have a path from producer → consumer.

Output: a verified `EmpTaskDag` attached to the region (or re-derivable).

Note: the current validator (`emp_parallel_validate.c`) is the start of this step. The final version becomes shared infrastructure for both validation and codegen.

### 1.2 DAG lowering (mid-end)

Input: verified `EmpTaskDag`

Responsibilities:
- Apply **task fusion** and other graph-level optimizations.
- Select scheduling strategy per region (`spawn` tasks vs structured parallel-for).
- Materialize task capture layouts (what values each node needs).

Output: a lowered DAG plan with:
- Node entry functions + context layouts
- Dependency lists / join points

### 1.3 LLVM IR emission (back-end)

Input: lowered DAG plan

Responsibilities:
- Emit LLVM IR for:
  - region entry
  - task bodies
  - runtime calls (threadpool scheduler)
  - joins / barriers (only where needed)
- Attach metadata (vectorization, cost hints, warnings)

---

## 2. DAG IR (compiler-internal)

### 2.1 Nodes

A node corresponds to a unit of execution:

- **Statement task**: one top-level statement inside `@emp parallel`.
- **Chain stage**: each stage in `~>` is a node (explicit ordering).
- **Parfor loop**: a structured node that can lower to a runtime parallel-for.
- **Reduction**: a structured node with per-worker accumulation + deterministic merge.

Each node has:
- `id`
- `kind`
- `span`
- `reads` and `writes` effect summary (resource keys)
- `captures_in`: values it needs
- `produces`: values it defines for later nodes

### 2.2 Edges

Edges represent happens-before.

Sources:
1. **Explicit edges**: from `~>`.
2. **Inferred temporal edges (allowed)**: local dataflow edges inside the region:
   - if node B reads a value produced by node A, then add edge A → B.
   - this supports temporal correctness without forcing the programmer to spell `~>` for every local.
3. **Shared-mutable edges (not inferred by default)**:
   - if conflict is on a *shared mutable resource*, it is an **error** unless it is:
     - explicitly chained, or
     - atomic, or
     - a reduction.

This preserves the “no shared-mutable without explicit ordering” rule while still allowing ergonomic local value flow.

### 2.3 Resource keys (effect system bridge)

To check independence and to compute legality, the compiler classifies accesses into resource keys:

- **Local key**: a binding defined inside the region (SSA-ish). Safe to infer edges.
- **Owned object key**: an object owned by the region and not aliased outside; can sometimes be treated like local.
- **Shared key**: anything that can be aliased across tasks:
  - bindings defined outside the region
  - globals/statics
  - heap objects reachable via shared references

The initial implementation can be conservative:
- Treat identifier-rooted accesses to names defined outside the region as shared.
- Treat region-local `let` bindings as local.

---

## 3. Legality rules (compile-time)

For each unordered pair of nodes (no path between them):

- Allowed:
  - read/read on same resource
  - read/write on **local** resource if we infer A → B (producer before consumer)
  - pure computations

- Forbidden unless explicitly handled:
  - write/write on shared resource
  - write/read on shared resource
  - any `io` effect unless the region is fully ordered or `@nondeterministic`

### 3.1 Atomics

Atomics are allowed only if they are modeled as:
- a deterministic commutative/associative reduction, or
- explicitly ordered.

Backend representation:
- atomics lower to LLVM atomic RMW / cmpxchg with appropriate ordering.

### 3.2 Reductions

A reduction node is the only **deterministic** way to “merge” parallel writes.

Rules:
- Reduction operator must be associative (and ideally commutative for performance).
- The merge order is fixed by the runtime (e.g., tree reduce) to maintain determinism.

---

## 4. Lowering strategy to LLVM IR

### 4.1 Runtime ABI (scheduler)

The compiler targets a small C ABI runtime (see `runtime/emp_rt.h`). Core primitives:

- `emp_rt_pool_init(nthreads)`
- `emp_rt_spawn(fn, ctx, deps, ndeps) -> handle`
- `emp_rt_wait(handle)`
- `emp_rt_parallel_for(begin, end, grain, body_fn, ctx)`

The runtime provides:
- work-stealing deques
- dependency-aware task readiness
- a deterministic reduction helper (optional)

### 4.2 Task capture

Each task becomes a static internal function:

- `void task_N(i8* ctx)`

`ctx` points to a compiler-generated struct with captured values.

Capture policy:
- Immutable values: copied by value when cheap, otherwise passed by pointer to immutable storage.
- Thread-local values: cloned per task (requires compiler-known clone or memcpy safe type).
- Shared mutable:
  - only passed as mutable pointer if ordered by dependencies (edge ensures exclusivity),
  - otherwise error unless atomic/reduction.

Implementation details:
- Use `alloca` in region entry for the context structs.
- Use `llvm.lifetime.start/end` intrinsics for stack objects.

### 4.3 Region lowering (`@emp parallel`)

Given a DAG with `k` nodes:

1. Emit node functions.
2. In region entry:
   - allocate contexts
   - compute dependency lists (handles)
   - call `emp_rt_spawn` for each node
   - only insert joins where required

**Barrier minimization**:
- If the region’s values are not used after the region, no join is required.
- If only some outputs are used, only wait for the producing subgraph.
- If exiting the region returns to sequential code with potential aliasing, wait for all tasks.

### 4.4 `~>` chain lowering

Chains become explicit edges.

Optimization:
- If chain stages are tiny and consecutive, fuse them into a single node to avoid scheduler overhead.

### 4.5 `parfor` lowering

Prefer structured parallel-for lowering:

- Determine iteration domain:
  - integer range (e.g. `0...n`) lowers directly
  - other iterables lower via an iterator protocol (future)

- Select grain size:
  - heuristics: `grain = max(1, (end-begin)/(8*nthreads))`
  - allow optional pragma later

- Emit body function:
  - `void parfor_body(i8* ctx, i64 begin, i64 end)`
  - loop from begin..end sequentially inside the worker

Work-stealing happens at the runtime chunk level.

### 4.6 Reduction lowering

Two forms:

1) Expr form: `reduce.sum(i in 0...n) { xs[i] }`

Lowering:
- runtime parallel_for over chunks
- each worker uses a stack accumulator initialized to identity (or provided init)
- combine into per-worker array
- merge deterministically (tree reduction in fixed order)

2) Block form: `reduce(acc: T = init, ...) parfor ... { ... }`

Lowering:
- identical structure, but with multiple accumulators

LLVM hints:
- mark the inner loop with `llvm.loop.vectorize.enable = true` when safe
- optionally insert `llvm.prefetch` for strided memory (heuristic)

---

## 5. Task fusion and graph optimizations

Goal: reduce scheduling overhead while preserving semantics.

### 5.1 Fusion heuristic

Fuse node A and B if:
- A → B is the only edge into B and the only edge out of A (linear chain)
- estimated cost(A)+cost(B) < threshold
- no cross-node captured large objects that would be duplicated by fusion

Cost model inputs:
- number of instructions (rough)
- calls present? (calls are “expensive” unless inlined)
- memory ops

### 5.2 Join elision

Do not emit a join barrier unless:
- required for uses after region exit
- required for drop semantics of values that live across tasks

### 5.3 Nested parallel regions

Nested regions are legal but should warn:
- oversubscription risk
- prefer flattening or using the same pool

The runtime should be re-entrant and should use the same global pool.

---

## 6. Warnings, metadata, and diagnostics

### 6.1 Warnings to emit

These are performance warnings (not errors):
- expensive clones into many tasks (large capture)
- unnecessary shared writes that force serialization
- over-chained computations (graph becomes mostly sequential)
- nested parallel loops (likely oversubscription)

Note: the current compiler diagnostics are “error-only” (any diag fails). Implementing warnings cleanly requires adding severity levels to `EmpDiag`.

### 6.2 LLVM metadata

Attach metadata for:
- loop vectorization (`llvm.loop.*`)
- memory access groups (`llvm.mem.parallel_loop_access`)
- custom `!emp.*` metadata for debug/analysis

---

## 7. Implementation plan (incremental, keeps tests green)

1. **Refactor shared access/effect analysis**
   - Extract the read/write set collector used by `emp_parallel_validate.c` into a reusable module.

2. **Build a real `EmpTaskDag` for each region**
   - Extend beyond chain edges to include local value-flow edges.
   - Keep “shared mutable edges must be explicit” as an error rule.

3. **Add a runtime ABI and a single-thread fallback**
   - Implement `emp_rt_spawn` as immediate call when runtime not enabled.

4. **Codegen path switch**
   - Add `--rt-parallel` (or build flag) later; do not change default until stable.

5. **Reductions**
   - Implement deterministic reduction lowering + runtime merge.

---

## 8. Notes on current repo state

- `emp_parallel_dag.*` already dumps a simple DAG for debugging.
- `multithreading_lowerer.*` is a temporary sequential desugaring for LLVM emission.
- `emp_parallel_validate.*` currently enforces deterministic conflicts for identifier-rooted accesses and respects `@nondeterministic`.

This design unifies those into the real backend path: **DAG IR → optimized schedule → LLVM + runtime**.
