# Test Index

This page explains the purpose of the test suite by folder and by naming, and provides a file-by-file index.

## Folder map

- `tests/lex/`: tokenization edge cases
- `tests/ll/`: LLVM lowering and IR-shape validations
- `tests/ownership/`: move/borrow errors and escape rules
- `tests/drop/`: deterministic destruction behavior
- `tests/mm/`: manual memory mode gating and semantics
- `tests/trait/`: trait checking and UFCS
- `tests/modules/`: module resolution behaviors
- `tests/control/`: loops, short-circuit, match, range for
- `tests/ffi/`: `extern` and unsafe call gating

## Reading a test name

- `*_ok.em` = must compile
- `*_fail.em` = must emit diagnostics

## IR snapshots

The harness also writes IR to `out/tests/ir/` for some suites. Those files are artifacts, not inputs.

## File-by-file index (all `.em` under `tests/`)

### Root

- `tests/hmp.em`: larger mixed-feature compiler test program.
- `tests/pam.em`: larger mixed-feature compiler test program.

### `tests/ast/` (parser/AST correctness)

- `tests/ast/array_size_canonical_ok.em`: array size normalization/canonicalization.
- `tests/ast/fstring_float_fail.em`: f-string placeholder rejecting floats (parser rule).
- `tests/ast/fstring_ok.em`: f-string parse success cases.
- `tests/ast/fstring_unescaped_rbrace_fail.em`: f-string brace escaping error case.
- `tests/ast/smoke_ok.em`: basic parse smoke.
- `tests/ast/string_index_ok.em`: parsing/typechecking of string indexing expression.
- `tests/ast/tag_ok.em`: tag/annotation parsing acceptance.
- `tests/ast/tuple_destructure_arity_fail.em`: tuple destructure arity mismatch diagnostic.
- `tests/ast/tuple_ok.em`: tuple syntax and basic semantics.

### `tests/borrow/` (borrow checker constraints)

- `tests/borrow/assign_while_borrowed_fail.em`: assigning to a binding while it is borrowed.
- `tests/borrow/list_assign_while_elem_borrowed_fail.em`: list assignment while an element borrow exists.
- `tests/borrow/list_elem_borrows_ok.em`: valid element borrows on lists.
- `tests/borrow/list_elem_mut_conflict_fail.em`: conflicting mutable element borrows.
- `tests/borrow/list_elem_shared_then_mut_fail.em`: shared-then-mut conflict on element borrows.
- `tests/borrow/mem_borrow.em`: valid borrow from memory/pointer scenario.
- `tests/borrow/mem_borrow_fail.em`: invalid borrow scenario involving memory/pointer.
- `tests/borrow/member_assign_while_borrowed_fail.em`: mutating a field while borrowed.
- `tests/borrow/member_method_call_after_scope_ok.em`: method calls after borrow scopes end.
- `tests/borrow/member_method_call_while_borrowed_fail.em`: calling a method while receiver/field is borrowed.
- `tests/borrow/move_after_inner_scope_ok.em`: move becomes legal after inner borrow scope ends.
- `tests/borrow/mut_ok_inner_scope.em`: mutable borrow within inner scope only.
- `tests/borrow/mut_then_shared_fail.em`: mutable then shared borrow conflict.
- `tests/borrow/move_while_borrowed_fail.em`: moving a value while it is borrowed.
- `tests/borrow/shared_ok.em`: multiple shared borrows allowed.
- `tests/borrow/shared_then_mut_fail.em`: shared then mutable borrow conflict.
- `tests/borrow/two_mut_fail.em`: two mutable borrows conflict.

### `tests/collections/` (built-in list behavior)

- `tests/collections/list_append_infer_ok.em`: `auto[]` element type inference succeeds.
- `tests/collections/list_append_infer_mismatch_fail.em`: `auto[]` inference mismatch diagnostics.
- `tests/collections/list_methods_len_cap_ok.em`: list method sugar for `len()` and `cap()`.

### `tests/control/` (control flow + defer)

- `tests/control/break_continue.em`: break/continue semantics.
- `tests/control/defer_basic_ok.em`: basic `defer {}` behavior.
- `tests/control/defer_loop_ok.em`: `defer` behavior in loops.
- `tests/control/defer_missing_block_fail.em`: `defer` requires a block.
- `tests/control/defer_return_ok.em`: `defer` runs on return/unwind.
- `tests/control/match.em`: basic `match` semantics.
- `tests/control/range_for_ok.em`: range-based for loop.
- `tests/control/range_for_two_bindings_fail.em`: invalid two-binding range-for form.
- `tests/control/short_circuit.em`: boolean short-circuit behavior.

### `tests/drop/` (deterministic destruction)

- `tests/drop/assign_drops_old_value.em`: assignment drops the previous owned value.
- `tests/drop/early_return_drop.em`: drops are inserted before early return.
- `tests/drop/emp_off_no_drops_inside.em`: drop insertion is skipped in `@emp off`.
- `tests/drop/move_no_double_drop.em`: moved values are not dropped twice.
- `tests/drop/params_drop.em`: function parameter drops.
- `tests/drop/scope_end_drop.em`: scope end drops.

### `tests/emp_mods/` (bundled module import behavior)

- `tests/emp_mods/alloc/arena.em`: arena module copy/import.
- `tests/emp_mods/math/basic.em`: math module copy/import.
- `tests/emp_mods/std/alloc.em`: std alloc module copy/import.
- `tests/emp_mods/std/mem.em`: std mem module copy/import.
- `tests/emp_mods/std/rawmem.em`: std rawmem module copy/import.
- `tests/emp_mods/time/duration.em`: duration module copy/import.

### `tests/emp_off/` (`@emp off` boundary rules)

- `tests/emp_off/borrow_escape_assign_fail.em`: borrow created in unsafe cannot escape via assignment.
- `tests/emp_off/borrow_escape_return_fail.em`: borrow created in unsafe cannot escape via return.
- `tests/emp_off/move_escape_fail.em`: moving an outer value in unsafe cannot silently escape.
- `tests/emp_off/no_escape_ok.em`: safe usage where nothing invalid escapes.

### `tests/ffi/` (extern/unsafe call gating)

- `tests/ffi/extern_call_inside_emp_off_ok.em`: extern call permitted inside `@emp off`.
- `tests/ffi/extern_call_requires_emp_off_fail.em`: extern call rejected outside `@emp off`.
- `tests/ffi/unsafe_fn_call_inside_emp_off_ok.em`: unsafe fn call permitted in unsafe block.
- `tests/ffi/unsafe_fn_call_requires_emp_off_fail.em`: unsafe fn call rejected outside `@emp off`.

### `tests/lex/` (lexer-only)

- `tests/lex/tokens_ok.em`: tokenization coverage.

### `tests/ll/` (LLVM lowering)

- `tests/ll/auto_infer_ok.em`: IR lowering with `auto` inference.
- `tests/ll/dyn_dispatch_ok.em`: dynamic dispatch works (virtual call).
- `tests/ll/dyn_missing_override_fail.em`: missing override diagnostic.
- `tests/ll/dyn_nonvirtual_fail.em`: invalid non-virtual dispatch diagnostic.
- `tests/ll/enum_construct_and_match_ok.em`: enum construction and match lowering.
- `tests/ll/enum_match_bindings_ok.em`: match bindings lowering.
- `tests/ll/enum_match_duplicate_fail.em`: duplicate match arm diagnostics.
- `tests/ll/enum_match_nonexhaustive_fail.em`: non-exhaustive match diagnostics.
- `tests/ll/fstring_interp_string_ok.em`: f-string interpolation behavior in lowering (current subset).
- `tests/ll/fstring_ok.em`: f-string lowering in accepted cases.
- `tests/ll/if_phi_ok.em`: if-expression/phi node lowering.
- `tests/ll/list_free_drops_elements_ok.em`: list free/drop interaction in lowering.
- `tests/ll/list_index_bounds_ok.em`: list index bounds behavior.
- `tests/ll/list_ops_ternary_ok.em`: list ops + ternary lowering.
- `tests/ll/list_reserve_pop_empty_ok.em`: reserve/pop empty list behavior.
- `tests/ll/lower_ops_ok.em`: operator lowering and precedence.
- `tests/ll/member_assign_nested_ok.em`: nested member assignment lowering.
- `tests/ll/method_call_nested_ok.em`: nested method call lowering.
- `tests/ll/method_call_temp_receiver_ok.em`: method calls with temporary receivers.
- `tests/ll/method_override_ok.em`: method override resolution/lowering.
- `tests/ll/method_overload_ok.em`: overload selection/lowering.
- `tests/ll/overload_free_ok.em`: freeing/overload behavior.
- `tests/ll/range_for_ok.em`: range-for lowering.
- `tests/ll/string_builtins_ok.em`: string builtins lowering.
- `tests/ll/string_index_ok.em`: string index lowering.
- `tests/ll/string_methods_ok.em`: string method sugar lowering.
- `tests/ll/trait_ufcs_ok.em`: UFCS lowering for traits.
- `tests/ll/tuple_destructure_ok.em`: tuple destructuring lowering.
- `tests/ll/tuple_index_nonconst_fail.em`: tuple indexing requires const index.
- `tests/ll/tuple_ok.em`: tuple lowering.

### `tests/math/`

- `tests/math/basic_ok.em`: math/basic module usage.

### `tests/mm/` (manual memory mode)

- `tests/mm/arena_alloc_inside_ok.em`: arena allocation allowed inside `@emp mm off`.
- `tests/mm/arena_alloc_outside_fail.em`: arena allocation rejected outside `@emp mm off`.
- `tests/mm/defer_in_mm_off_ok.em`: `defer` used for cleanup in MM-off.
- `tests/mm/mm_call_inside_ok.em`: mm primitive call allowed inside MM-off.
- `tests/mm/mm_call_outside_fail.em`: mm primitive call rejected outside MM-off.
- `tests/mm/mm_file_directive_ok.em`: file-wide `@emp mm off;` works.
- `tests/mm/std_mm_call_inside_emp_off_fail.em`: `@emp off` alone does not allow mm primitives.
- `tests/mm/std_mm_call_inside_ok.em`: std mm primitives allowed inside MM-off.
- `tests/mm/std_mm_call_outside_fail.em`: std mm primitives rejected outside MM-off.

### `tests/modules/` (module resolution)

- `tests/modules/ambiguous/lib.em`: ambiguous import candidate library.
- `tests/modules/ambiguous/main.em`: ambiguous resolution example.
- `tests/modules/ambiguous/main_fail.em`: ambiguous resolution error case.
- `tests/modules/ambiguous_pkg/main.em`: ambiguous package-resolution example.
- `tests/modules/ambiguous_pkg/main_fail.em`: ambiguous package-resolution error case.
- `tests/modules/ambiguous_pkg/pkg/a.em`: module used by ambiguous package tests.
- `tests/modules/emp_mods/lib.em`: module resolution via emp_mods.
- `tests/modules/emp_mods/pkg/b.em`: module under a package-like folder.
- `tests/modules/missing/main.em`: missing module import example.
- `tests/modules/missing/main_fail.em`: missing import produces error.

### `tests/overload_ambiguous_fail.em`

- `tests/overload_ambiguous_fail.em`: ambiguous overload resolution diagnostic.

### `tests/ownership/` (move checking)

- `tests/ownership/if_maybe_moved.em`: conditional move tracking (ok case).
- `tests/ownership/if_maybe_moved_fail.em`: conditional move tracking (error case).
- `tests/ownership/return_moved.em`: returning moved value (ok case).
- `tests/ownership/return_moved_fail.em`: returning a moved-from value (error).
- `tests/ownership/use_after_move.em`: use-after-move (ok variant in controlled form).
- `tests/ownership/use_after_move_fail.em`: use-after-move diagnostic.

### `tests/time/`

- `tests/time/duration_ok.em`: duration module usage.

### `tests/trait/` (trait checking)

- `tests/trait/trait_missing_impl_fail.em`: missing impl diagnostic.
- `tests/trait/trait_missing_method_fail.em`: missing method diagnostic.
- `tests/trait/trait_sig_mismatch_fail.em`: signature mismatch diagnostic.

### `tests/vendor_*` (vendoring behavior)

These are end-to-end tests that ensure stdlib modules can be vendored into a project layout.

- `tests/vendor_alloc/src/main_ok.em`: vendors alloc-related std modules.
- `tests/vendor_math/src/main_ok.em`: vendors math/basic.
- `tests/vendor_std/src/main_ok.em`: vendors std modules.
- `tests/vendor_time/src/main_ok.em`: vendors time/duration.

Vendored module copies used by these tests:

- `tests/vendor_alloc/emp_mods/alloc/arena.em`
- `tests/vendor_alloc/emp_mods/std/alloc.em`
- `tests/vendor_alloc/emp_mods/std/mem.em`
- `tests/vendor_alloc/emp_mods/std/rawmem.em`
- `tests/vendor_math/emp_mods/math/basic.em`
- `tests/vendor_std/emp_mods/std/console.em`
- `tests/vendor_std/emp_mods/std/option.em`
- `tests/vendor_time/emp_mods/time/duration.em`
