# Getting Started

## Build (Windows)

This repo uses CMake presets and builds an `emp.exe`.

Typical flow:

```text
cmake --preset make-x64-debug
cmake --build --preset make-x64-debug
```

The binary is typically placed under:

- `out/build/make-x64/Debug/emp.exe`

The build also copies `stdlib/` next to the compiler so imports can resolve.

## Hello world

Create `hello.em`:

```emp
fn main() {
  return;
}
```

Compile:

```text
out\build\make-x64\Debug\emp.exe hello.em
```

## Running tests

```text
powershell -ExecutionPolicy Bypass -File .\tests\run_tests.ps1
```

If needed:

```text
powershell -ExecutionPolicy Bypass -File .\tests\run_tests.ps1 -EmpExe out\build\make-x64\Debug\emp.exe
```
