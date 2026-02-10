# CLI

EMP’s compiler binary accepts a source path and optional mode flags.

## Common commands

- Build a native exe (default when a file is provided):

```text
emp.exe file.em
```

- Emit LLVM IR without producing a native binary:

```text
emp.exe --nobin --out out.ll file.em
```

- Emit LLVM IR (alias):

```text
emp.exe --ll --out out.ll file.em
```

- Parse and print the AST:

```text
emp.exe --ast file.em
```

- Emit JSON:

```text
emp.exe --json --out out.json file.em
```

## Inputs

- EMP source files use `.em`.
- If you pass a path with no extension, `.em` is appended.

For test convenience, EMP also accepts a file that contains exactly one Markdown code fence wrapping EMP source.
