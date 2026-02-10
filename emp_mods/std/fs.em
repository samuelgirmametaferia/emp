// std.fs (minimal)
// Windows implementation; only the pieces used by examples/bench_parallel_forward.em

export struct FileResult {
    is_ok: bool;
    value: i32; // bytes read/written
    error: i32;
    handle: u64;
}

export struct File {
    handle: u64;
}

// --- Win32 Externs ---
extern "C" fn CreateFileA(lpFileName: *u8, dwDesiredAccess: u32, dwShareMode: u32, lpSecurityAttributes: *u8, dwCreationDisposition: u32, dwFlagsAndAttributes: u32, hTemplateFile: u64) -> u64;
extern "C" fn ReadFile(hFile: u64, lpBuffer: *u8, nNumberOfBytesToRead: u32, lpNumberOfBytesRead: *u32, lpOverlapped: *u8) -> i32;
extern "C" fn WriteFile(hFile: u64, lpBuffer: *u8, nNumberOfBytesToWrite: u32, lpNumberOfBytesWritten: *u32, lpOverlapped: *u8) -> i32;
extern "C" fn CloseHandle(hObject: u64) -> i32;
extern "C" fn GetFileSizeEx(hFile: u64, lpFileSize: *u64) -> i32;
extern "C" fn GetLastError() -> i32;
extern "C" fn lstrlenA(s: *u8) -> i32;
extern "C" fn GetFileAttributesA(lpFileName: *u8) -> u32;
extern "C" fn CreateDirectoryA(lpPathName: *u8, lpSecurityAttributes: *u8) -> i32;

// --- Constants ---
// NOTE: This compiler build appears to have issues resolving module-level
// constants in some contexts, so we mostly inline numeric constants.

// NOTE: This minimal std.fs uses Win32 *A functions (ANSI) to avoid wide-string
// conversion issues in this compiler build.

fn okResult() -> FileResult {
    let r: FileResult;
    r.is_ok = true;
    r.value = 0;
    r.error = 0;
    r.handle = 0;
    return r;
}

fn errResult(err: i32) -> FileResult {
    let r: FileResult;
    r.is_ok = false;
    r.value = 0;
    r.error = err;
    r.handle = 0;
    return r;
}

// --- Query ---

export fn exists(path: *u8) -> bool {
    let attrs: u32;
    @emp off { attrs = GetFileAttributesA(path); }
    return attrs != 4294967295;
}

export fn isDir(path: *u8) -> bool {
    let attrs: u32;
    @emp off { attrs = GetFileAttributesA(path); }
    if attrs == 4294967295 { return false; }
    return (attrs & 16) != 0;
}

// --- Directories ---

export fn dirCreate(path: *u8) -> FileResult {
    let ok: i32;
    @emp off { ok = CreateDirectoryA(path, null); }

    if ok != 0 { return okResult(); }

    let err: i32;
    @emp off { err = GetLastError(); }
    if err == 183 { return okResult(); }
    return errResult(err);
}

// --- Files ---

export fn fileCreate(path: u8[]) -> FileResult {
    // Back-compat overload for older code paths.
    let _unused: u8[] = path;
    return errResult(-1);
}

export fn fileCreateZ(path: *u8) -> FileResult {
    let h: u64;
    @emp off {
        // DesiredAccess = GENERIC_READ | GENERIC_WRITE = 3221225472
        h = CreateFileA(path, 3221225472, 3, null, 2, 128, 0);
    }
    if h == (u64)(-1) {
        let err: i32;
        @emp off { err = GetLastError(); }
        return errResult(err);
    }

    let r: FileResult = okResult();
    r.handle = h;
    return r;
}

export fn fileOpen(path: u8[]) -> FileResult {
    let _unused: u8[] = path;
    return errResult(-1);
}

export fn fileOpenZ(path: *u8) -> FileResult {
    let h: u64;
    @emp off {
        h = CreateFileA(path, 2147483648, 1, null, 3, 128, 0);
    }
    if h == (u64)(-1) {
        let err: i32;
        @emp off { err = GetLastError(); }
        return errResult(err);
    }

    let r: FileResult = okResult();
    r.handle = h;
    return r;
}

export fn fileCloseHandle(handle: u64) -> FileResult {
    if handle == 0 { return okResult(); }
    let ok: i32;
    @emp off { ok = CloseHandle(handle); }
    if ok == 0 {
        let err: i32;
        @emp off { err = GetLastError(); }
        return errResult(err);
    }
    return okResult();
}

export fn fileClose(f: File) -> FileResult {
    return fileCloseHandle(f.handle);
}

export fn fileSizeHandle(handle: u64) -> u64 {
    let size: u64 = 0;
    let success: i32;
    @emp off { success = GetFileSizeEx(handle, &mut size); }
    if success == 0 { return (u64)0; }
    return size;
}

export fn fileSize(f: File) -> u64 {
    return fileSizeHandle(f.handle);
}

export fn fileWriteHandle(handle: u64, data: u8[]) -> FileResult {
    let n: i32 = data.len();
    if n <= 0 {
        let r: FileResult = okResult();
        r.value = 0;
        return r;
    }

    // NOTE: This compiler build cannot reliably produce pointers to array/list
    // elements. Write byte-at-a-time using a pointer to a local.
    let totalWritten: i32 = 0;
    let i: i32 = 0;
    while i < n {
        let b: u8 = data[i];
        let wrote: u32 = 0;
        let ok: i32;
        @emp off { ok = WriteFile(handle, &mut b, 1, &mut wrote, null); }
        if ok == 0 {
            let err: i32;
            @emp off { err = GetLastError(); }
            return errResult(err);
        }
        if wrote == 0 { break; }
        totalWritten = totalWritten + 1;
        i = i + 1;
    }

    let r: FileResult = okResult();
    r.value = totalWritten;
    return r;
}

export fn fileWrite(f: File, data: u8[]) -> FileResult {
    return fileWriteHandle(f.handle, data);
}

export fn fileReadIntoHandle(handle: u64, dst: *u8, n: i32) -> FileResult {
    if n <= 0 {
        let r: FileResult = okResult();
        r.value = 0;
        return r;
    }

    let read: u32 = 0;
    let ok: i32;
    @emp off { ok = ReadFile(handle, dst, (u32)n, &mut read, null); }

    if ok == 0 {
        let err: i32;
        @emp off { err = GetLastError(); }
        return errResult(err);
    }

    let r: FileResult = okResult();
    r.value = (i32)read;
    return r;
}

// Read the full file into an output list.
export fn fileReadAllHandle(handle: u64, out: *u8[]) -> FileResult {
    // NOTE: Read byte-at-a-time for the same reason as fileWriteHandle.
    let total: i32 = 0;
    while true {
        let b: u8 = 0;
        let read: u32 = 0;
        let ok: i32;
        @emp off { ok = ReadFile(handle, &mut b, 1, &mut read, null); }

        if ok == 0 {
            let err: i32;
            @emp off { err = GetLastError(); }
            return errResult(err);
        }

        if read == 0 { break; }
        list_push(out, b);
        total = total + 1;
    }

    let r: FileResult = okResult();
    r.value = total;
    return r;
}

export fn fileReadInto(f: File, dst: *u8, n: i32) -> FileResult {
    return fileReadIntoHandle(f.handle, dst, n);
}
