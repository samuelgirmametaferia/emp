# Lexing & Syntax

This section documents the surface syntax **as implemented** by the lexer and parser.

For a token-by-token list, see **Lexer Tokens**.

## Quick tour (one snippet)

```emp
// Line comment
/* Block comments are nestable: /* like this */
*/

@emp mm off; // file-wide manual memory mode

#trace; // tag statement (accepted by the parser)

fn main() {
  let x: i32 = 1_000;
  let y = .25e2;
  let raw = `multiline
no escapes processed`;
  let s = $"x={x}, y={y}, braces={{}}";

  // Ranges and ternary
  let r = 0..=10;
  let z = x > 0 ? x : -x;

  return;
}
```

## Whitespace and newlines

- Spaces and tabs are ignored.
- Newlines are significant only for diagnostics.
- Windows `\r\n` is normalized by the lexer (CRLF and lone CR both behave as a newline).

## Comments

- Line comments: `// ...` (to end of line)
- Block comments: `/* ... */`
  - Block comments are **nestable** (`/* /* */ */`).

## Identifiers

- Start: `_` or ASCII letter `[A-Za-z]`
- Continue: start chars plus digits `[0-9]`

## Keywords

Keywords are lexed (not identifiers). The current keyword set is:

`fn auto let mut if else while for in return break continue struct enum match defer true false null emp mm off export use from as extern unsafe class trait virtual new impl const dyn`

## Literals

### Integers

Accepted forms include:

- Decimal: `123`, `0`, `10_000`
- Hex: `0xFF`, `0x12_ab`
- Binary: `0b1010_0101`
- Octal: `0o755`

Underscore rules (strict):

- No leading underscore
- No trailing underscore
- No consecutive underscores

### Floats

Accepted forms include:

- `1.0`, `0.25`, `10_000.5`
- Leading-dot float: `.123`
- Exponent: `1e9`, `1.0e-3`

### Strings

- Escaped string: `"..."` (single line)
  - Supports escapes: `\\`, `\"`, `\'`, `\n`, `\r`, `\t`, `\0`, `\xNN`, `\u{HEX}` (1–6 hex digits)
  - A raw newline inside `"..."` is a lex error.
- Raw string: `` `...` `` (multiline allowed)
  - No escapes are processed.

### f-strings

Lexed as a single token:

- Escaped: `$"..."` (single line)
- Raw: `` $`...` `` (multiline)

Interpolation rules are handled by the parser:

- `{expr}` inserts an expression
- `{{` produces a literal `{`
- `}}` produces a literal `}`
- A lone `}` is a parse diagnostic

### Chars

- Char literal: `'a'` or escaped forms like `'\n'`
- Empty `''` is an error
- Multi-char payload (e.g. `'ab'`) is an error

## Punctuation and operators

The lexer recognizes (non-exhaustive grouping):

- Delimiters: `() { } [ ] , ;`
- Member/paths: `.`, `::`
- Ranges: `..`, `..=`, `...`
- Arithmetic: `+ - * / %`
- Bitwise: `& | ^ ~`, shifts `<< >>`
- Boolean: `&& || !`
- Comparison: `== != < <= > >=`
- Assignment: `=`, plus `+= -= *= /= %= &= |= ^= <<= >>=`
- Other: `->` (return type), `=>` (match arm), `? :` (ternary)

Operator precedence is defined by the parser; see **Grammar (Implemented)**.

For “real world” examples of each construct, use the [Runner](#__runner__) and load any test under `tests/`.
