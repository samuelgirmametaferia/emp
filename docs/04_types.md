# Types

EMP is statically typed.

Most type syntax shows up in:

- `let` annotations: `let x: Type = expr;`
- Function parameters and returns: `fn f(Type x) -> Type { ... }`

Use the [Runner](#__runner__) to load `tests/ll/tuple_ok.em`, `tests/ll/auto_infer_ok.em`, and `tests/ast/array_size_canonical_ok.em`.

## Primitives

Common primitives used across tests and stdlib:

- `bool`
- Signed integers: `i8`, `i16`, `i32`, `i64`, `isize`
- Unsigned integers: `u8`, `u16`, `u32`, `u64`, `usize`

## Pointers and borrows

### Raw pointers (types)

- `*T` is a pointer type.

### Borrows (expressions)

Borrowing is an expression form:

- `&expr` (shared borrow)
- `&mut expr` (mutable borrow)

## Arrays and lists

- Fixed-size arrays: `T[n]`
- Dynamic lists: `T[]`

Notes (as implemented):

- `T[]` and `T[n]` are parsed as a **postfix** on an already-parsed type `T`.
- Only one postfix `[...]` is parsed by the current `parse_type` implementation.

Example:

```emp
fn f(i32 a) {
	let xs: i32[] = [1, 2, 3];
	let buf: u8[16];
	return;
}
```

## Tuple types

Tuple types use parentheses:

- `(T, U)`
- `(T a, U b)` (field names are optional and currently parsed but not required)

## `dyn` types

`dyn` types are parsed as:

- `dyn BaseName`

Where `BaseName` is an identifier.

See **Arrays & Lists** for details.

## `auto`

`auto` is used when the compiler can infer the concrete type.

EMP also uses `auto` in some stdlib APIs (e.g. `Option::Some(auto)`) as a temporary stand-in until generics are fully implemented.

## User-defined types

- `struct` for product types (named fields)
- `enum` for sum types (variants)

EMP also has object-oriented features (classes and methods) used in examples/tests.
