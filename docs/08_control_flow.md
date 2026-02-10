# Control Flow

## `if` / `else`

EMP supports conditional branching with `if` and optional `else`.

As implemented:

- `if <expr> { ... }`
- `if <expr> stmt;` (a single statement body is allowed; the parser wraps it in a block)
- `else if ...` chains
- `else { ... }` or `else stmt;`

## Loops

EMP supports:

### `while`

- `while <expr> { ... }` (body must be a block)

### `for`

Two forms are parsed:

- `for idx in <expr> { ... }`
- `for idx, val in <expr> { ... }`

The body must be a block.

## `break` / `continue`

As implemented:

- `break;`
- `continue;`

## `return`

Returns from a function. In safe mode, drop insertion ensures owned locals are destroyed even on early return.

## `match`

Pattern matching is parsed as:

```emp
match <expr> {
	<pat-expr> => { ... }
	else => { ... }
}
```

Notes:

- Each arm body must be a block.
- Arms may optionally be separated by `,` or `;`.
- The default arm uses the keyword `else`.

Example (arm separators are optional):

```emp
match v {
	0 => { return; },
	1 => { return; }
	else => { return; }
}
```

## `defer`

`defer { ... }` is a statement form; the body must be a block.

Execution semantics are implemented in later passes (LIFO order on scope exit) and are heavily used for cleanup in `@emp mm off` regions.
