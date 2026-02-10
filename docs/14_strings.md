# Strings

## Literals

- Escaped: `"..."`
- Raw multiline: `` `...` ``

## f-strings (interpolation)

EMP reserves `$` as the f-string prefix.

Current status:

- f-strings are lexed as a single token: `$"..."` or `` $`...` ``.
- The parser splits them into parts:
	- Text segments
	- `{expr}` segments (full expressions are parsed between braces)
- Brace escaping is supported: `{{` and `}}`.

Examples:

```emp
fn main() {
	let x = 12;
	let s = $"x={x} braces={{}}";
	return;
}
```

## Built-in string operations

EMP has compiler-supported string helpers that can be used via method-call sugar.

Common operations:

- `s.len()`
- `s.clone()`
- `s.parse_i32()`
- `s.parse_bool()`
- `s.starts_with(prefix)`
- `s.ends_with(suffix)`
- `s.contains(needle)`
- `s.replace(from, to)`

See `tests/ll/string_methods_ok.em` and `tests/ll/string_builtins_ok.em`.

