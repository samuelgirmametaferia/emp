# EMP Multithreading + Determinism (Design Doc)

This document describes the next major EMP feature: a **single, formally defined concurrency model** that combines:

- **Automatic parallelism** (where safe and deterministic)
- **Manual parallel control** (when the programmer wants it)

…under a unified, **DAG-based execution model**, with:

- **Rust-level safety guarantees** (no data races, no use-before-ready)
- **Stronger compile-time semantics** (effect system + temporal typing)
- **Determinism by default** (explicit opt-in required for nondeterministic behavior)

This is a **spec-first** doc: it defines syntax, typing rules, validation rules, runtime semantics, and compiler lowering.

---

## 1. Goals

### 1.1 Primary goals

1. **Deterministic-by-default parallel execution**
   - Same input -> same output, independent of scheduling.
2. **No shared-mutable concurrency without explicit ordering**
   - If two tasks can write (or write/read) the same state, the program must explicitly serialize them.
3. **Unify all concurrency constructs as a DAG**
   - `@emp parallel`, `~>` chaining, `parfor`, and reductions all lower into the same intermediate representation.
4. **Static validation of parallel programs**
   - The compiler rejects invalid parallelism (data races, stale reads, missing ordering).
5. **Portable backends**
   - DAG IR should target CPU thread pools now, and later GPU/async backends.

### 1.2 Non-goals (initial phase)

- Preemptive threads with shared-mutable locks/mutexes (forbidden by design).
- Allowing nondeterministic data races “because the user knows better” without explicit opt-in.
- Implementing async/await in this same phase (but the DAG IR should be compatible with an async runtime later).

---

## 2. Single Execution Model: DAG of Tasks

EMP concurrency is defined in terms of a **directed acyclic graph** (DAG):

- Nodes: **tasks** (units of execution)
- Edges: **happens-before** constraints
- Values can flow along edges as **typed outputs**

### 2.1 Determinism

A program is **deterministic** if:

- All tasks that can run concurrently are **independent** (no conflicting effects), and
- The only allowed communication between tasks is via:
  - typed value flow along explicit edges, and
  - deterministic reductions.

If ordering is not specified, the compiler assumes tasks may run in parallel; if that creates ambiguity in observable behavior, the compiler rejects it.

---

## 3. `@emp parallel`: Deterministic Parallel Region

### 3.1 Syntax

A parallel region is introduced by:

```emp
@emp parallel {
  // statements
}
```

Semantics:

- The region body is lowered into a DAG.
- **Each statement is a task by default**, unless the compiler proves it must be fused.
- Tasks are scheduled on a runtime thread pool.

### 3.2 Default independence

Inside `@emp parallel`:

- Statements are assumed **independent** and may execute concurrently.
- If the compiler cannot validate independence, it produces a compile-time error.

---

## 4. `~>` Chaining Operator: Explicit Ordering + Typed Value Flow

### 4.1 Purpose

The `~>` operator creates a **strict happens-before edge** and (optionally) propagates typed outputs.

- `A ~> B` means:
  - Task `A` completes before task `B` begins.
  - Values produced in `A` may be used in `B` with the correct temporal type.

### 4.2 Syntax variants

Minimal ordering:

```emp
stmtA ~> stmtB;
```

Typed value propagation (conceptual):

```emp
let x = compute();
(x) ~> use(x);
```

More explicit dataflow form (proposed sugar):

```emp
let x = task compute();
x ~> task use(x);
```

(Exact sugar is flexible; the core is: edges exist and carry typed outputs.)

### 4.3 Rules

- **All shared-mutable writes require chaining**.
- Any write effect that could conflict with another task must be explicitly ordered.
- The compiler rejects programs where the task graph implies cycles.

---

## 5. Effect System (Compile-time Classification)

Every expression/task is assigned an **effect**. Effects form a lattice and are checked compositionally.

### 5.1 Effect kinds

- `pure` — no reads/writes of shared state; deterministic.
- `read<T>` — reads shared state resource `T`.
- `write<T>` — writes shared state resource `T`.
- `atomic<T>` — atomic read-modify-write on resource `T` (still deterministic only if modeled as reduction or ordered).
- `io` — external effects (files, network, console). Treated as nondeterministic unless explicitly ordered or constrained.

A “resource `T`” is a compile-time abstraction (examples):

- a variable binding (by identity),
- a field of an owned object,
- a global/module static,
- an abstract capability token.

### 5.2 Parallelization rule

Inside `@emp parallel`:

- Tasks with effects only in `pure` or `read<...>` may be auto-parallelized.
- Any `write<...>` task must be:
  - explicitly chained with all conflicting tasks, or
  - expressed as a deterministic reduction.
- `io` is forbidden unless:
  - explicitly chained into a total order inside the region, or
  - annotated `@nondeterministic` (opt-in).

### 5.3 “Shared-mutable write without chain” is an error

Example error:

```emp
@emp parallel {
  x = x + 1;   // write<x>
  x = x + 2;   // write<x>
}
```

Rejected: both write the same resource `x` with no ordering.

Valid version:

```emp
@emp parallel {
  x = x + 1 ~> x = x + 2;
}
```

(Exact syntax may differ, but the idea is a strict edge.)

---

## 6. Temporal Typing (When Values Become Valid)

The type system tracks not only *what* a value is, but *when* it is available.

### 6.1 Temporal type forms

- `T@now` — available immediately in the current task.
- `T@after(TaskId)` — produced by some task; only usable after that task completes.
- `T@chain<C>` — available after chain context `C` (a compile-time representation of a happens-before path).

These are conceptual; the compiler can represent this as hidden qualifiers/regions.

### 6.2 Use-before-ready is a compile-time error

```emp
@emp parallel {
  let x = compute();
  use(x); // error unless there is a chain from compute -> use
}
```

Valid:

```emp
@emp parallel {
  let x = compute();
  compute() ~> use(x);
}
```

(Again: syntax is flexible; the rule is strict happens-before for temporal validity.)

### 6.3 Preventing stale reads

If `x` is written in a task, reads of `x` in other tasks must be temporally after the write, or the compiler rejects.

---

## 7. Manual Parallel Loops: `parfor`

`parfor` is usable **outside** parallel regions, and lowers into the same DAG IR.

### 7.1 Syntax (proposed)

```emp
parfor i in 0...n {
  body(i);
}
```

### 7.2 Semantics

- Each iteration is a task.
- Loop index `i` is implicitly **thread-local / task-local**.
- Captured variables must be:
  - immutable (`read<...>`), or
  - explicitly declared as reductions.
- Inter-iteration ordering is forbidden.
- There is an implicit **join barrier** at loop exit.

### 7.3 Restrictions

- No writes to shared state unless it is a reduction.
- No mutation of captured variables without reduction semantics.

Rejected:

```emp
let sum: i32 = 0;
parfor i in 0...n {
  sum += xs[i]; // error: shared write without reduction
}
```

Valid with deterministic reduction:

```emp
let sum = reduce.sum(i in 0...n) { xs[i] };
```

(or an explicit reduction block form; see next section.)

---

## 8. First-class Deterministic Reductions

Mutexes are forbidden by design; deterministic reductions replace them.

### 8.1 Reduction operators

Built-in deterministic reductions (initial set):

- `sum` (numeric)
- `max` / `min`
- `count`
- `concat` (strings/lists with deterministic order rules)

### 8.2 Semantics

- Each task produces a **local accumulator**.
- The runtime performs a guaranteed **merge phase**.
- The merge is deterministic:
  - either by a defined associativity/commutativity requirement, or
  - by a specified merge order.

### 8.3 Formal constraints

To preserve determinism:

- A reduction function must be:
  - `pure`, and
  - associative (and preferably commutative), unless the merge order is defined.

If floating-point reductions are allowed, determinism requires a specified merge order and/or exact rules.

### 8.4 Reduction syntax (proposed)

Expression form:

```emp
let s: i32 = reduce.sum(i in 0...n) { xs[i] };
```

Or block form:

```emp
let s: i32 = reduce(sum: i32 = 0) parfor i in 0...n {
  sum += xs[i];
};
```

(The compiler lowers both into: per-iteration accumulator + deterministic merge.)

---

## 9. Nondeterminism: Explicit Opt-in

Determinism is the default.

### 9.1 `@nondeterministic`

A program may opt into unordered execution only with explicit annotation:

```emp
@nondeterministic
@emp parallel {
  // allowed: unordered IO, racy reads, etc (still memory safe, but not deterministic)
}
```

What this unlocks:

- unordered task scheduling without deterministic merge guarantees
- `io` tasks without strict chaining

What it does **not** unlock:

- memory unsafety (no undefined behavior)
- data races that violate the borrow/ownership model (still rejected)

---

## 10. Task-local State (Not Thread-local)

EMP forbids thread-local state as a semantic primitive.

Instead:

- Provide **task-local state**: values scoped to a task and its descendants in the DAG.
- Task-local is deterministic because it follows explicit DAG edges.

Proposed API direction:

- `task_local<T>` keys
- `task_local.get/set` only within a task context

---

## 11. Failure, Cancellation, and Join Semantics

Tasks can fail; failure handling must be deterministic.

### 11.1 Failure model

- A task may produce either a value or an error.
- Failure propagation rules are explicit:
  - fail-fast for the region (cancel remaining tasks), or
  - collect errors (deterministic ordering of collection).

### 11.2 Cancellation

- Cancellation is cooperative.
- Cancellation is a runtime signal; tasks must check cancellation points.

### 11.3 Join

- `@emp parallel` has an implicit join at end of region.
- `parfor` has an implicit join at loop exit.

---

## 12. Unified DAG-based Intermediate Representation (IR)

All concurrency constructs lower into a shared IR.

### 12.1 IR goals

- Express tasks, edges, and typed values.
- Encode effects and temporal validity.
- Enable backend scheduling decisions.

### 12.2 Proposed IR shape (conceptual)

- `Task(id, inputs, outputs, effect, body)`
- `Edge(src, dst, carried_values)`
- `Region(kind, tasks, edges, join_policy, nondet_flag)`

### 12.3 Backend mapping

- CPU thread pool: schedule ready tasks; enforce edges.
- Future GPU: map independent pure/read tasks to kernels.
- Future async: map tasks to futures; edges to awaits.

---

## 13. Compile-time Validation Rules

A parallel program is valid if the compiler can prove:

1. The lowered task graph is a DAG.
2. For any two tasks that may run concurrently:
   - their effects do not conflict, or
   - they are ordered by `~>`, or
   - the conflict is expressed as a deterministic reduction.
3. All value uses satisfy temporal typing constraints (no use-before-ready).
4. `io` is either totally ordered or explicitly marked nondeterministic.

If any rule fails: compile-time error.

---

## 14. Interaction with Ownership/Borrowing

This system should integrate with EMP’s existing safety passes:

- Ownership/borrow checking remains the baseline memory safety layer.
- Concurrency adds additional constraints:
  - shared mutable aliasing across concurrent tasks is forbidden unless serialized via chaining or expressed as reductions.

Important principle:

- `~>` is an ordering primitive, not a “permission to share mutable references.”
- The borrow checker should still prevent holding `&mut` across parallel boundaries unless that boundary is serialized.

---

## 15. Examples

### 15.1 Safe automatic parallelism

```emp
@emp parallel {
  let a = f(x);     // pure
  let b = g(y);     // pure
  let c = a + b;    // depends on a and b (requires edges)
}
```

The compiler may lower `f(x)` and `g(y)` as parallel tasks, then chain both into `c`.

### 15.2 Shared mutation requires explicit chain

```emp
@emp parallel {
  x = x + 1; // write<x>
  y = x + 2; // read<x> (conflicts with write<x>)
}
```

Rejected unless the user writes:

```emp
@emp parallel {
  x = x + 1 ~> y = x + 2;
}
```

### 15.3 parfor with reduction

```emp
let total: i32 = reduce.sum(i in 0...n) { xs[i] };
```

---

## 16. Implementation Roadmap (Compiler)

This section outlines *where* this will live in the compiler, without committing to final APIs.

1. Lexer/parser:
   - Parse `@emp parallel {}`
   - Parse `~>` chaining operator in statement grammar
   - Parse `parfor` loop form
   - Parse reduction constructs

2. AST:
   - New statement kinds for parallel region and parfor
   - New node for chain edges / chained statement sequences
   - Reduction nodes

3. Semantic/typecheck:
   - Effect inference + checking
   - Temporal typing constraints
   - Determinism enforcement

4. Lowering:
   - Build a DAG IR from the region
   - Insert join nodes, merge nodes for reductions

5. Codegen/runtime:
   - Initial backend: CPU thread pool runtime
   - Deterministic merge implementations
   - Cancellation propagation

---

## 17. Open Questions

- Exact surface syntax for typed output propagation across `~>`.
- How to name/identify effect resources (`T`) precisely (binding identity vs memory region tokens).
- Whether `io` inside parallel regions is allowed only with chaining, or requires nondeterministic opt-in.
- Floating-point determinism strategy (merge ordering vs disallow by default).
- Interaction with `@emp off` and `@emp mm off` blocks inside parallel regions.
