// Minimal C FFI surface used by emp_mods.
// These declarations are unsafe to call directly; use wrappers in higher-level modules.

export extern "C" fn cPrint(msg: auto);
export extern "C" fn cAdd(a: i32, b: i32) -> i32;
