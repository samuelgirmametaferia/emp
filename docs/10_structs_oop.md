# Structs & OOP

## Structs

Structs are product types (named fields). See usage in examples and tests.

## Methods and call sugar

EMP supports method call syntax. For some built-in types (lists and strings), member calls are lowered to compiler builtins.

Examples:

- `xs.push(v)` on a `T[]` list
- `s.starts_with(prefix)` on a `string`

## Classes (OOP)

EMP includes class/object-oriented syntax used in `examples/oop.em` and related import examples.

Because this area is actively evolving, treat tests and examples as the canonical truth for now.
