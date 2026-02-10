// std.console
//
// Console I/O for Windows.
//
// Goals:
// - Basic output should not require `@emp off` in application code.
// - Advanced console operations are wrapped in safe helpers.
// - Allocation stays explicit: functions that allocate are `mm`-gated.

extern "C" fn GetStdHandle(nStdHandle: i32) -> *u8;
extern "C" fn lstrlenA(s: *u8) -> i32;
extern "C" fn WriteFile(hFile: *u8, lpBuffer: *u8, nNumberOfBytesToWrite: u32, lpNumberOfBytesWritten: *u32, lpOverlapped: *u8) -> i32;
extern "C" fn ReadFile(hFile: *u8, lpBuffer: *u8, nNumberOfBytesToRead: u32, lpNumberOfBytesRead: *u32, lpOverlapped: *u8) -> i32;

extern "C" fn GetConsoleMode(hConsoleHandle: *u8, lpMode: *u32) -> i32;
extern "C" fn SetConsoleMode(hConsoleHandle: *u8, dwMode: u32) -> i32;
extern "C" fn FlushConsoleInputBuffer(hConsoleInput: *u8) -> i32;

extern "C" fn SetStdHandle(nStdHandle: i32, hHandle: *u8) -> i32;
extern "C" fn FreeConsole() -> i32;

extern "C" fn SetConsoleTitleA(lpConsoleTitle: *u8) -> i32;
extern "C" fn Beep(dwFreq: u32, dwDuration: u32) -> i32;
extern "C" fn Sleep(dwMilliseconds: u32);

// Screen buffer ops.
extern "C" fn GetConsoleScreenBufferInfo(hConsoleOutput: *u8, lpInfo: *ConsoleScreenBufferInfo) -> i32;
extern "C" fn SetConsoleTextAttribute(hConsoleOutput: *u8, wAttributes: u16) -> i32;
extern "C" fn SetConsoleCursorPosition(hConsoleOutput: *u8, dwCursorPosition: Coord) -> i32;
extern "C" fn FillConsoleOutputCharacterA(hConsoleOutput: *u8, cCharacter: u8, nLength: u32, dwWriteCoord: Coord, lpNumberOfCharsWritten: *u32) -> i32;
extern "C" fn FillConsoleOutputAttribute(hConsoleOutput: *u8, wAttribute: u16, nLength: u32, dwWriteCoord: Coord, lpNumberOfAttrsWritten: *u32) -> i32;
extern "C" fn SetConsoleScreenBufferSize(hConsoleOutput: *u8, dwSize: Coord) -> i32;
extern "C" fn SetConsoleWindowInfo(hConsoleOutput: *u8, bAbsolute: i32, lpConsoleWindow: *SmallRect) -> i32;

use {allocBytes, freeBytes} from std.alloc;
use {set} from std.mem;

export const stdIn: i32 = -10;
export const stdOut: i32 = -11;
export const stdErr: i32 = -12;

// Console mode flags (subset).
export const enableEchoInput: u32 = 0x0004;
export const enableLineInput: u32 = 0x0002;
export const enableProcessedInput: u32 = 0x0001;
export const enableVirtualTerminalInput: u32 = 0x0200;
export const enableVirtualTerminalProcessing: u32 = 0x0004;

export struct Coord {
  x: i16;
  y: i16;
}

export struct SmallRect {
  left: i16;
  top: i16;
  right: i16;
  bottom: i16;
}

export struct ConsoleScreenBufferInfo {
  size: Coord;
  cursor: Coord;
  attributes: u16;
  _pad: u16;
  window: SmallRect;
  maxWindowSize: Coord;
}

fn handleIn() -> *u8 {
  @emp off { return GetStdHandle(-10); }
}

fn handleOut() -> *u8 {
  @emp off { return GetStdHandle(-11); }
}

fn handleErr() -> *u8 {
  @emp off { return GetStdHandle(-12); }
}

fn writeBytes(h: *u8, p: *u8, n: u32) {
  @emp off {
    let written: u32 = 0;
    WriteFile(h, p, n, &mut written, null);
  }
}

fn cstrLenU32(s: *u8) -> u32 {
  @emp off { return (u32)lstrlenA(s); }
}

// ---- Write / WriteLine ----

export fn write(s: *u8) {
  let h: *u8 = handleOut();
  writeBytes(h, s, cstrLenU32(s));
}

export fn writeLine(s: *u8) {
  write(s);
  write("\n");
}

export fn writeError(s: *u8) {
  let h: *u8 = handleErr();
  writeBytes(h, s, cstrLenU32(s));
}

export fn writeErrorLine(s: *u8) {
  writeError(s);
  writeError("\n");
}

export fn writeString(s: string) {
  let h: *u8 = handleOut();
  @emp off {
    let p: *u8 = string_cstr(&s);
    let n: u32 = (u32)string_len(&s);
    writeBytes(h, p, n);
  }
}

export fn writeLineString(s: string) {
  writeString(s);
  write("\n");
}

export fn writeErrorString(s: string) {
  let h: *u8 = handleErr();
  @emp off {
    let p: *u8 = string_cstr(&s);
    let n: u32 = (u32)string_len(&s);
    writeBytes(h, p, n);
  }
}

export fn writeErrorLineString(s: string) {
  writeErrorString(s);
  writeError("\n");
}

// Back-compat with earlier tiny API.
export fn print(s: *u8) { write(s); }
export fn println(s: *u8) { writeLine(s); }

// ---- Timing ----

// Best-effort delay for animations.
export fn sleepMillis(ms: i32) {
  if ms <= 0 { return; }
  @emp off { Sleep((u32)ms); }
}

// ---- Single-byte output ----

export fn writeChar(ch: u8) {
  let h: *u8 = handleOut();
  let b: u8 = ch;
  writeBytes(h, &mut b, 1);
}

export fn writeCharC(ch: char) {
  let h: *u8 = handleOut();
  let c: char = ch;
  // Pointers are opaque in EMP right now; this is good enough for WriteFile.
  writeBytes(h, &mut c, 1);
}

export fn carriageReturn() {
  write("\r");
}

// ---- Animations (minimal primitives) ----

export fn spinnerFrame(tick: i32) -> *u8 {
  let t: i32 = tick;
  if t < 0 { t = 0; }
  let m: i32 = t % 4;
  if m == 0 { return "|"; }
  if m == 1 { return "/"; }
  if m == 2 { return "-"; }
  return "\\";
}

// Writes a single spinner frame on the current line:
//   "\r<frame> <label>"
export fn spinnerStep(tick: i32, label: *u8) -> i32 {
  let t: i32 = tick;
  let next: i32 = t + 1;
  carriageReturn();
  write(spinnerFrame(t));
  write(" ");
  write(label);
  return next;
}

// Draws a simple progress bar on the current line.
// Example: "\r[#####.....]"
export fn progressBar(current: i32, total: i32, width: i32) {
  let w: i32 = width;
  if w <= 0 { w = 10; }

  let filled: i32;
  if total <= 0 {
    filled = 0;
  } else {
    if current <= 0 {
      filled = 0;
    } else if current >= total {
      filled = w;
    } else {
      filled = (current * w) / total;
    }
  }

  carriageReturn();
  writeChar(91); // '['
  for i in 0...w {
    if i < filled {
      writeChar(35); // '#'
    } else {
      writeChar(46); // '.'
    }
  }
  writeChar(93); // ']'
}

// ---- Read / ReadLine / ReadKey ----

// Reads one byte from stdin.
// Returns -1 on EOF/no data, else 0..255.
export fn read() -> i32 {
  let h: *u8 = handleIn();
  let b: u8 = 0;
  let got: u32 = 0;
  @emp off {
    ReadFile(h, &mut b, 1, &mut got, null);
  }
  if got == 0 { return -1; }
  return (i32)b;
}

// Reads a single key (best-effort).
// Note: for real key events / function keys we will eventually want ReadConsoleInput.
export fn readKey() -> i32 {
  // Temporarily disable line and echo input so a single keypress can be read.
  let h: *u8 = handleIn();
  let mode: u32 = 0;
  let ok: bool;
  @emp off {
    ok = GetConsoleMode(h, &mut mode) != 0;
  }
  if ok {
    let newMode: u32 = mode & (~enableLineInput) & (~enableEchoInput);
    @emp off { SetConsoleMode(h, newMode); }
  }

  let v: i32 = read();

  if ok {
    @emp off { SetConsoleMode(h, mode); }
  }
  return v;
}

// Reads into a caller-provided buffer, NUL-terminating it.
// Returns true if any bytes were read.
export fn readLineInto(buf: *u8, cap: u32, outLen: *u32) -> bool {
  if cap == 0 { *outLen = 0; return false; }

  let h: *u8 = handleIn();
  let i: u32 = 0;

  while i + 1 < cap {
    let ch: u8 = 0;
    let got: u32 = 0;
    @emp off {
      ReadFile(h, &mut ch, 1, &mut got, null);
    }
    if got == 0 {
      break;
    }

    if ch == 10 { // '\n'
      break;
    }
    if ch == 13 { // '\r'
      // Swallow optional following '\n'.
      let peek: u8 = 0;
      let got2: u32 = 0;
      @emp off {
        ReadFile(h, &mut peek, 1, &mut got2, null);
      }
      if got2 != 0 {
        if peek != 10 {
          // Can't un-read; just treat as a regular char by appending it.
          @emp off { buf[i] = peek; }
          i = i + 1;
        }
      }
      break;
    }

    @emp off { buf[i] = ch; }
    i = i + 1;
  }

  @emp off {
    buf[i] = 0;
    *outLen = i;
  }
  return i != 0;
}

// Convenience: allocates a buffer, reads a line, returns a new string.
// Manual-MM only.
export mm fn readLine(maxBytes: i32) -> string {
  let cap: u32 = (u32)(maxBytes + 1);
  let p: *u8 = allocBytes(cap);
  set(p, 0, cap);

  let n: u32 = 0;
  let _ok: bool = readLineInto(p, cap, &mut n);

  let s: string = string_from_cstr(p);
  freeBytes(p);
  return s;
}

export fn flushInput() {
  let h: *u8 = handleIn();
  @emp off { FlushConsoleInputBuffer(h); }
}

// ---- Utility ----

export fn beep() {
  @emp off { Beep(750, 200); }
}

export fn clear() {
  let h: *u8 = handleOut();
  let info: ConsoleScreenBufferInfo;
  let ok: bool;
  @emp off { ok = GetConsoleScreenBufferInfo(h, &mut info) != 0; }
  if !ok { return; }

  let w: u32 = (u32)(i32)info.size.x;
  let hgt: u32 = (u32)(i32)info.size.y;
  let cells: u32 = w * hgt;

  let home: Coord;
  home.x = 0;
  home.y = 0;

  let written: u32 = 0;
  @emp off {
    FillConsoleOutputCharacterA(h, 32, cells, home, &mut written); // ' '
    FillConsoleOutputAttribute(h, info.attributes, cells, home, &mut written);
    SetConsoleCursorPosition(h, home);
  }
}

export fn setCursorPosition(left: i32, top: i32) {
  let h: *u8 = handleOut();
  let c: Coord;
  c.x = (i16)left;
  c.y = (i16)top;
  @emp off { SetConsoleCursorPosition(h, c); }
}

export fn setTitle(title: *u8) -> bool {
  let ok: bool;
  @emp off { ok = SetConsoleTitleA(title) != 0; }
  return ok;
}

// Color encoding matches Win32 console attributes.
// 0..15 for foreground/background.
export fn setColor(fg: u16, bg: u16) {
  let h: *u8 = handleOut();
  let attrs: u16 = (fg & 0x0F) | ((bg & 0x0F) << 4);
  @emp off { SetConsoleTextAttribute(h, attrs); }
}

export fn resetColor() {
  setColor(7, 0);
}

export fn setSize(cols: i32, rows: i32) -> bool {
  // Best-effort: set buffer size then window size.
  let hout: *u8 = handleOut();
  let size: Coord;
  size.x = (i16)cols;
  size.y = (i16)rows;

  let ok1: bool;
  @emp off { ok1 = SetConsoleScreenBufferSize(hout, size) != 0; }

  let rect: SmallRect;
  rect.left = 0;
  rect.top = 0;
  rect.right = (i16)(cols - 1);
  rect.bottom = (i16)(rows - 1);

  let ok2: bool;
  @emp off { ok2 = SetConsoleWindowInfo(hout, 1, &mut rect) != 0; }
  return ok1 && ok2;
}

export fn freeConsole() -> bool {
  let ok: bool;
  @emp off { ok = FreeConsole() != 0; }
  return ok;
}

// Redirection helpers (process-wide).
export fn setInHandle(h: *u8) -> bool {
  let ok: bool;
  @emp off { ok = SetStdHandle(-10, h) != 0; }
  return ok;
}

export fn setOutHandle(h: *u8) -> bool {
  let ok: bool;
  @emp off { ok = SetStdHandle(-11, h) != 0; }
  return ok;
}

export fn setErrorHandle(h: *u8) -> bool {
  let ok: bool;
  @emp off { ok = SetStdHandle(-12, h) != 0; }
  return ok;
}
