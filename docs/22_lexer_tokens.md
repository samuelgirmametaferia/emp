# Lexer Tokens

This page is a concise reference for what the lexer recognizes (token kinds, keywords, literals, punctuation).

Authority:

- `emp_lexer.h` defines the token kinds.
- `emp_lexer.c` implements scanning.

## Keywords

These spellings are recognized as keywords:

- `fn`, `auto`, `let`, `mut`
- `if`, `else`, `while`, `for`, `in`, `return`, `break`, `continue`
- `struct`, `enum`, `match`, `defer`
- `true`, `false`, `null`
- `export`, `use`, `from`, `as`
- `extern`, `unsafe`
- `class`, `trait`, `virtual`, `new`, `impl`, `const`, `dyn`
- `emp`, `mm`, `off` (used in `@emp ...` directives)

## Literals

- Integers: decimal, `0x` hex, `0b` binary, `0o` octal; underscores are allowed with strict rules.
- Floats: decimal forms, leading-dot `.123`, optional exponent `e`/`E` with optional `+`/`-`.
- Strings: `"..."` (escaped, single-line) and `` `...` `` (raw, multiline)
- f-strings: `$"..."` and `` $`...` ``
- Chars: `'a'` and escaped variants (exactly one payload unit)

## Comments

- `// line`
- `/* block */` (nestable)

## Operators and punctuation

Delimiters:

- `(` `)` `{` `}` `[` `]` `,` `;`

Member/path/range:

- `.` `::` `..` `..=` `...`

Operators:

- `+ - * / %`
- `& | ^ ~ !`
- `== != < <= > >=`
- `&& ||`
- `<< >>`
- Assignments: `= += -= *= /= %= &= |= ^= <<= >>=`

Other:

- `->` (return type)
- `=>` (match arms)
- `?` and `:` (ternary)
- `@` (directives) and `#` (tag statement/item)
