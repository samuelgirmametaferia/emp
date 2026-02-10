# Grammar (Implemented)

This is a practical grammar guide based on `emp_parser.c`.

It’s intentionally written in “what the parser accepts” form rather than a formal EBNF.

## Top-level items

Parsed as a sequence of items until EOF:

- `@emp mm off;` (file-level directive)
- `#tag` (optional `;`)
- Modifiers: `export`, `extern`, `unsafe`, `mm` (can stack)
- `fn ...` (function)
- `use ...;` (imports)
- `const name [: Type] = expr;`
- `struct Name { field: Type; ... }`
- `enum Name { Variant(Type, ...), Variant2; ... }`
- `class Name [: Base] { fields and methods }`
- `trait Name { fn sig(...)->T; ... }`
- `impl Type { fn ... { ... } }`
- `impl Trait for Type { fn ... { ... } }`

## Statements

The parser accepts (high level):

- Blocks: `{ stmt* }`
- Tags: `#name` (optional `;`)
- Directives:
  - `@emp off { ... }`
  - `@emp mm off { ... }`
- `let` bindings:
  - `let name [: Type] [= expr];`
  - Tuple destructure: `let (a, b, _) [: Type] [= expr];`
    - `_` is accepted and rewritten to a generated internal name
- `defer { ... }`
- `return [expr];`
- `if expr { ... } [else if ...] [else ...]`
  - `then` and `else` bodies may be `{...}` or a single statement (wrapped into a block)
- `while expr { ... }`
- `for idx [ , val ] in expr { ... }`
- `break;` / `continue;`
- `match expr { arms }`
  - arm: `<expr> => { ... }` or `else => { ... }`
- Expression statement: `expr;`

## Expressions

Primary expressions:

- Literals: int, float, string, char
- f-strings: `$"..."` or `` $`...` `` with `{expr}` parts
- Identifiers and keyword-literals (`true`/`false`/`null` are parsed as identifier-like expressions)
- Grouping: `(expr)` and empty `()`
- Tuple expressions: `(a, b, c)` (triggered by a comma)
- List literals: `[a, b, c]` (trailing comma allowed)
- `new ClassName(args...)`

Postfix:

- Call: `callee(args...)`
- Member: `expr.name`
- Namespace/member: `expr::name`
- Index: `expr[expr]`
- Cast: `expr as Type`

Prefix:

- Unary: `-expr`, `!expr`, `~expr`, `&expr`, `&mut expr`
- Narrow C-style casts: `(i32)expr`, `(u64)expr`, `(f32)expr`, etc. (restricted set)

Infix (selected):

- Arithmetic: `* / %` then `+ -`
- Shifts: `<< >>`
- Comparisons: `< <= > >=` then `== !=`
- Bitwise: `&` then `^` then `|`
- Boolean: `&&` then `||`
- Assignment: `=`, `+=`, ... (right associative)
- Range: `..`, `..=`, `...` (between shifts/comparisons and assignment)
- Ternary: `cond ? then : else` (between `||/&&` and assignment)

## Types

- `auto`
- `dyn Name`
- Pointer type: `*Type`
- Named type: `Name`
- Tuple type: `(Type [name], Type [name], ...)`
- Postfix list/array:
  - `Type[]`
  - `Type[123]` (size is an INT token; underscores allowed; parser canonicalizes it)

For concrete precedence details, see `parse_expr_bp` and `infix_bp` in `emp_parser.c`.