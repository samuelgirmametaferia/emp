// std.console
//
// Minimal printing API intended for application code.
// NOTE: Using Win32 WriteFile here conflicts with std.fs externs in this compiler
// build (extern overloading leads to mangled symbol names and the codegen then
// drops the call sites). Use C runtime `puts` instead.

extern "C" fn puts(s: *u8) -> i32;

export fn print(s: *u8) {
  @emp off { puts(s); }
}

export fn println(s: *u8) {
  @emp off { puts(s); }
}
