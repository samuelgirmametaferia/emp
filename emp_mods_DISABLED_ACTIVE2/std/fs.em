// std.fs
// Windows implementation

export struct FileResult {
    is_ok: bool;
    value: i32; // bytes read/written or other code
    error: i32;
    handle: u64;
}

export struct File {
    handle: u64;
}

export struct DirEntry {
    name: u8[];
    is_dir: bool;
}

export struct Metadata {
    file_size: u64;
    created: u64;
    accessed: u64;
    modified: u64;
    attrs: u32;
    is_dir: bool;
    is_readonly: bool;
}

// --- Win32 Externs ---

extern "C" fn CreateFileW(lpFileName: *u16, dwDesiredAccess: u32, dwShareMode: u32, lpSecurityAttributes: *u8, dwCreationDisposition: u32, dwFlagsAndAttributes: u32, hTemplateFile: u64) -> u64;
extern "C" fn ReadFile(hFile: u64, lpBuffer: *u8, nNumberOfBytesToRead: u32, lpNumberOfBytesRead: *u32, lpOverlapped: *u8) -> i32;
extern "C" fn WriteFile(hFile: u64, lpBuffer: *u8, nNumberOfBytesToWrite: u32, lpNumberOfBytesWritten: *u32, lpOverlapped: *u8) -> i32;
extern "C" fn CloseHandle(hObject: u64) -> i32;
extern "C" fn DeleteFileW(lpFileName: *u16) -> i32;
extern "C" fn MoveFileW(lpExistingFileName: *u16, lpNewFileName: *u16) -> i32;
extern "C" fn CopyFileW(lpExistingFileName: *u16, lpNewFileName: *u16, bFailIfExists: i32) -> i32;
extern "C" fn CreateDirectoryW(lpPathName: *u16, lpSecurityAttributes: *u8) -> i32;
extern "C" fn RemoveDirectoryW(lpPathName: *u16) -> i32;
extern "C" fn GetFileSizeEx(hFile: u64, lpFileSize: *u64) -> i32;
extern "C" fn GetLastError() -> i32;
extern "C" fn MultiByteToWideChar(CodePage: u32, dwFlags: u32, lpMultiByteStr: *u8, cbMultiByte: i32, lpWideCharStr: *u16, cchWideChar: i32) -> i32;
extern "C" fn WideCharToMultiByte(CodePage: u32, dwFlags: u32, lpWideCharStr: *u16, cchWideChar: i32, lpMultiByteStr: *u8, cbMultiByte: i32, lpDefaultChar: *u8, lpUsedDefaultChar: *i32) -> i32;
extern "C" fn GetFileAttributesW(lpFileName: *u16) -> u32;
extern "C" fn GetFileAttributesExW(lpFileName: *u16, fInfoLevelId: i32, lpFileInformation: *u8) -> i32;
extern "C" fn FindFirstFileW(lpFileName: *u16, lpFindFileData: *u8) -> u64;
extern "C" fn FindNextFileW(hFindFile: u64, lpFindFileData: *u8) -> i32;
extern "C" fn FindClose(hFindFile: u64) -> i32;
extern "C" fn SetFilePointerEx(hFile: u64, liDistanceToMove: i64, lpNewFilePointer: *i64, dwMoveMethod: u32) -> i32;
extern "C" fn FlushFileBuffers(hFile: u64) -> i32;
extern "C" fn GetFullPathNameW(lpFileName: *u16, nBufferLength: u32, lpBuffer: *u16, lpFilePart: *u64) -> u32;

// --- Constants ---
let CP_UTF8: u32 = 65001;
let GENERIC_READ: u32 = 2147483648; 
let GENERIC_WRITE: u32 = 1073741824;

let CREATE_ALWAYS: u32 = 2;
let OPEN_EXISTING: u32 = 3;
let OPEN_ALWAYS: u32 = 4;

let FILE_ATTRIBUTE_READONLY: u32 = 1;
let FILE_ATTRIBUTE_NORMAL: u32 = 128; // 0x80
let FILE_ATTRIBUTE_DIRECTORY: u32 = 16;
let INVALID_FILE_ATTRIBUTES: u32 = 4294967295;
let INVALID_HANDLE: u64 = 0xFFFFFFFFFFFFFFFF;

let FILE_BEGIN: u32 = 0;
let FILE_CURRENT: u32 = 1;
let FILE_END: u32 = 2;

// --- Helpers ---

// Convert UTF-8 slice to Null-Terminated Wide string
fn utf8ToWide(s: u8[]) -> u16[] {
    let slen: i32 = s.len();
    if slen == 0 {
        let empty: u16[];
        empty.push(0);
        return empty;
    }

    let wlen: i32;
    @emp off {
        let p: *u8 = &s[0];
        wlen = MultiByteToWideChar(CP_UTF8, 0, p, slen, 0, 0);
    }
    
    // Allocate (wlen + 1) for null terminator
    let buf: u16[];
    let i: i32 = 0;
    while i < wlen {
        buf.push(0);
        i = i + 1;
    }
    buf.push(0); // Null terminator

    if wlen > 0 {
        @emp off {
            let p_in: *u8 = &s[0];
            let p_out: *u16 = &buf[0];
            MultiByteToWideChar(CP_UTF8, 0, p_in, slen, p_out, wlen);
        }
    }
    
    return buf;
}

// Convert Null-Terminated Wide String Pointer to UTF-8 slice
fn wideToUtf8(w: *u16) -> u8[] {
    let len: i32;
    @emp off {
        len = WideCharToMultiByte(CP_UTF8, 0, w, -1, 0, 0, null, null);
    }
    
    if len <= 0 { 
        let e: u8[]; 
        return e; 
    }
    
    let buf: u8[];
    let i: i32 = 0;
    while i < len { 
        buf.push(0); 
        i = i + 1; 
    }
    
    @emp off {
        let pOut: *u8 = &buf[0];
        WideCharToMultiByte(CP_UTF8, 0, w, -1, pOut, len, null, null);
    }
    
    // Remove null terminator if present
    if buf.len() > 0 {
        if buf[buf.len() - 1] == 0 {
            buf.pop();
        }
    }
    return buf;
}

// --- CORE Implementation ---

export fn fileOpen(path: u8[]) -> FileResult {
    let wpath: u16[] = utf8ToWide(path);
    let h: u64;
    @emp off {
        let wp: *u16 = &wpath[0];
        h = CreateFileW(wp, GENERIC_READ, 1, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0); 
    }
    if h == INVALID_HANDLE {
        let r: FileResult; r.is_ok = false; @emp off { r.error = GetLastError(); } return r;
    }
    let r: FileResult; r.is_ok = true; r.handle = h; return r;
}

export fn fileCreate(path: u8[]) -> FileResult {
    let wpath: u16[] = utf8ToWide(path);
    let h: u64;
    @emp off {
        let wp: *u16 = &wpath[0];
        h = CreateFileW(wp, GENERIC_WRITE, 0, null, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    }
    if h == INVALID_HANDLE {
        let r: FileResult; r.is_ok = false; @emp off { r.error = GetLastError(); } return r;
    }
    let r: FileResult; r.is_ok = true; r.handle = h; return r;
}

// Open or Create if missing, for appending/rw
export fn fileOpenAppend(path: u8[]) -> FileResult {
    let wpath: u16[] = utf8ToWide(path);
    let h: u64;
    // Read & Write access
    let access: u32 = GENERIC_READ | GENERIC_WRITE;
    @emp off {
        let wp: *u16 = &wpath[0];
        h = CreateFileW(wp, access, 0, null, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    }
    if h == INVALID_HANDLE {
        let r: FileResult; r.is_ok = false; @emp off { r.error = GetLastError(); } return r;
    }
    
    // Seek to end
    @emp off {
        SetFilePointerEx(h, 0, null, FILE_END);
    }

    let r: FileResult; r.is_ok = true; r.handle = h; return r;
}

export fn fileRead(f: File, buf: u8[]) -> FileResult {
    let len: i32 = buf.len();
    if len == 0 { let r: FileResult; r.is_ok = true; r.value = 0; return r; }
    
    let h: u64 = f.handle;
    let read: u32 = 0;
    let success: i32;
    let nBytes: u32 = (u32)len;

    @emp off {
        let p: *u8 = &buf[0];
        success = ReadFile(h, p, nBytes, &mut read, null);
    }

    if success == 0 {
         let r: FileResult; r.is_ok = false; @emp off { r.error = GetLastError(); } return r;
    }

    let r: FileResult; r.is_ok = true; r.value = (i32)read; return r;
}

export fn fileWrite(f: File, data: u8[]) -> FileResult {
    let len: i32 = data.len();
    if len == 0 { let r: FileResult; r.is_ok = true; r.value = 0; return r; }

    let h: u64 = f.handle;
    let written: u32 = 0;
    let success: i32;
    let nBytes: u32 = (u32)len;

    @emp off {
        let p: *u8 = &data[0];
        success = WriteFile(h, p, nBytes, &mut written, null);
    }

    if success == 0 {
        let r: FileResult; r.is_ok = false; @emp off { r.error = GetLastError(); } return r;
    }
    let r: FileResult; r.is_ok = true; r.value = (i32)written; return r;
}

export fn fileClose(f: File) {
    @emp off { CloseHandle(f.handle); }
}

export fn fileSeek(f: File, offset: i64, whence: i32) -> i64 {
    let h: u64 = f.handle;
    let success: i32;
    let newPos: i64 = 0;
    let method: u32 = FILE_BEGIN;
    if whence == 1 { method = FILE_CURRENT; }
    if whence == 2 { method = FILE_END; }

    @emp off {
        success = SetFilePointerEx(h, offset, &mut newPos, method);
    }
    
    if success == 0 { return -1; }
    return newPos;
}

export fn fileSync(f: File) -> bool {
    let s: i32;
    @emp off { s = FlushFileBuffers(f.handle); }
    return s != 0;
}

// --- Operations ---

export fn fileDelete(path: u8[]) -> FileResult {
    let wpath: u16[] = utf8ToWide(path);
    let success: i32;
    @emp off { let wp: *u16 = &wpath[0]; success = DeleteFileW(wp); }
    if success == 0 {
        let r: FileResult; r.is_ok = false; @emp off { r.error = GetLastError(); } return r;
    }
    let r: FileResult; r.is_ok = true; return r;
}

export fn fileRename(oldPath: u8[], newPath: u8[]) -> FileResult {
    let wold: u16[] = utf8ToWide(oldPath);
    let wnew: u16[] = utf8ToWide(newPath);
    let success: i32;
    @emp off {
        let p1: *u16 = &wold[0]; let p2: *u16 = &wnew[0];
        success = MoveFileW(p1, p2);
    }
    if success == 0 {
        let r: FileResult; r.is_ok = false; @emp off { r.error = GetLastError(); } return r;
    }
    let r: FileResult; r.is_ok = true; return r;
}

export fn fileCopy(src: u8[], dst: u8[], overwrite: bool) -> FileResult {
    let wsrc: u16[] = utf8ToWide(src);
    let wdst: u16[] = utf8ToWide(dst);
    let failIfExists: i32 = 1; if overwrite { failIfExists = 0; }
    let success: i32;
    @emp off {
        let p1: *u16 = &wsrc[0]; let p2: *u16 = &wdst[0];
        success = CopyFileW(p1, p2, failIfExists);
    }
    if success == 0 {
        let r: FileResult; r.is_ok = false; @emp off { r.error = GetLastError(); } return r;
    }
    let r: FileResult; r.is_ok = true; return r;
}

// --- Directory ---

export fn dirCreate(path: u8[]) -> FileResult {
    let wpath: u16[] = utf8ToWide(path);
    let success: i32;
    @emp off { let wp: *u16 = &wpath[0]; success = CreateDirectoryW(wp, null); }
    if success == 0 {
        let err: i32; @emp off { err = GetLastError(); }
        let r: FileResult; r.is_ok = false; r.error = err; return r;
    }
    let r: FileResult; r.is_ok = true; return r;
}

export fn dirRemove(path: u8[]) -> FileResult {
    let wpath: u16[] = utf8ToWide(path);
    let success: i32;
    @emp off { let wp: *u16 = &wpath[0]; success = RemoveDirectoryW(wp); }
    if success == 0 {
        let r: FileResult; r.is_ok = false; @emp off { r.error = GetLastError(); } return r;
    }
    let r: FileResult; r.is_ok = true; return r;
}

export fn readDir(path: u8[]) -> DirEntry[] {
    let entries: DirEntry[];
    // path + "\\*"
    let searchPath: u8[];
    let i: i32 = 0;
    while i < path.len() { searchPath.push(path[i]); i = i + 1; }
    if searchPath.len() > 0 {
        let last: u8 = searchPath[searchPath.len() - 1];
        if last != 92 && last != 47 { searchPath.push(92); }
    }
    searchPath.push(42); // *
    
    let wpath: u16[] = utf8ToWide(searchPath);
    let findData: u8[];
    let k: i32 = 0; while k < 600 { findData.push(0); k=k+1; }
    
    let hFind: u64;
    @emp off {
        let wp: *u16 = &wpath[0]; let fd: *u8 = &findData[0];
        hFind = FindFirstFileW(wp, fd);
    }
    if hFind == INVALID_HANDLE { return entries; }
    
    let keepGoing: i32 = 1;
    while keepGoing != 0 {
        let nameUtf8: u8[];
        let is_dir: bool = false;
        let pName: *u16;
        @emp off {
            let fd: *u8 = &findData[0];
            let attrs: u32 = *(u32*)fd;
            is_dir = (attrs & 16) != 0;
            pName = (u16*)(fd + 44);
        }
        nameUtf8 = wideToUtf8(pName);
        let skip: bool = false;
        if nameUtf8.len() == 1 && nameUtf8[0] == 46 { skip = true; } 
        else if nameUtf8.len() == 2 && nameUtf8[0] == 46 && nameUtf8[1] == 46 { skip = true; }

        if !skip {
            let ent: DirEntry; ent.name = nameUtf8; ent.is_dir = is_dir;
            entries.push(ent);
        }
        @emp off { let fd: *u8 = &findData[0]; keepGoing = FindNextFileW(hFind, fd); }
    }
    @emp off { FindClose(hFind); }
    return entries;
}

export fn removeDirAll(path: u8[]) -> FileResult {
    if !exists(path) { let r: FileResult; r.is_ok=true; return r; }
    if !isDir(path) { return fileDelete(path); }
    let entries: DirEntry[] = readDir(path);
    let i: i32 = 0;
    while i < entries.len() {
        let ent: DirEntry = entries[i];
        let subPath: u8[];
        let k: i32 = 0; while k < path.len() { subPath.push(path[k]); k=k+1; }
        if subPath.len() > 0 {
            if subPath[subPath.len()-1] != 92 && subPath[subPath.len()-1] != 47 { subPath.push(92); }
        }
        let m: i32 = 0; while m < ent.name.len() { subPath.push(ent.name[m]); m=m+1; }
        if ent.is_dir {
            let r: FileResult = removeDirAll(subPath); if !r.is_ok { return r; }
        } else {
            let r: FileResult = fileDelete(subPath); if !r.is_ok { return r; }
        }
        i = i + 1;
    }
    return dirRemove(path);
}

// --- Query ---

export fn exists(path: u8[]) -> bool {
    let wpath: u16[] = utf8ToWide(path);
    let attrs: u32;
    @emp off { let wp: *u16 = &wpath[0]; attrs = GetFileAttributesW(wp); }
    return attrs != INVALID_FILE_ATTRIBUTES;
}

export fn isDir(path: u8[]) -> bool {
    let wpath: u16[] = utf8ToWide(path);
    let attrs: u32;
    @emp off { let wp: *u16 = &wpath[0]; attrs = GetFileAttributesW(wp); }
    if attrs == INVALID_FILE_ATTRIBUTES { return false; }
    return (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0;
}

export fn isFile(path: u8[]) -> bool {
    let wpath: u16[] = utf8ToWide(path);
    let attrs: u32;
    @emp off { let wp: *u16 = &wpath[0]; attrs = GetFileAttributesW(wp); }
    if attrs == INVALID_FILE_ATTRIBUTES { return false; }
    return (attrs & FILE_ATTRIBUTE_DIRECTORY) == 0;
}

export fn fileSize(f: File) -> u64 {
    let size: u64 = 0;
    let success: i32;
    let h: u64 = f.handle;
    @emp off { success = GetFileSizeEx(h, &mut size); }
    if success == 0 { return 0; }
    return size;
}

// --- Metadata & Paths ---

export fn absPath(path: u8[]) -> u8[] {
    let wpath: u16[] = utf8ToWide(path);
    let wbuf: u16[];
    let i: i32 = 0;
    // MAX_PATH is 260 but we can go higher. Allocated 512 u16s.
    while i < 512 { wbuf.push(0); i=i+1; }
    
    let len: u32;
    @emp off {
        let wp: *u16 = &wpath[0];
        let wb: *u16 = &wbuf[0];
        len = GetFullPathNameW(wp, 512, wb, null);
    }
    if len == 0 || len >= 512 { return path; } // Fail fallback

    // Re-terminate:
    wbuf[len] = 0;
    
    @emp off {
        let wb: *u16 = &wbuf[0];
        return wideToUtf8(wb);
    }
    return path; // unreachable
}

export fn metadata(path: u8[]) -> Metadata {
    let wpath: u16[] = utf8ToWide(path);
    let buffer: u8[];
    let k: i32 = 0; while k < 36 { buffer.push(0); k=k+1; }
    
    let success: i32;
    @emp off {
        let wp: *u16 = &wpath[0];
        let b: *u8 = &buffer[0];
        // GetFileAttributesExW, Level 0 (GetFileExInfoStandard)
        success = GetFileAttributesExW(wp, 0, b);
    }
    
    let m: Metadata;
    if success == 0 { return m; } // Zeroed

    // Manually unpack WIN32_FILE_ATTRIBUTE_DATA
    @emp off {
        let b: *u8 = &buffer[0];
        m.attrs = *(u32*)b;
        m.created = *(u64*)(b + 4);
        m.accessed = *(u64*)(b + 12);
        m.modified = *(u64*)(b + 20);
        let szHi: u32 = *(u32*)(b + 28);
        let szLo: u32 = *(u32*)(b + 32);
        m.file_size = ((u64)szHi << 32) | (u64)szLo;
    }
    
    m.is_dir = (m.attrs & FILE_ATTRIBUTE_DIRECTORY) != 0;
    m.is_readonly = (m.attrs & FILE_ATTRIBUTE_READONLY) != 0;
    
    return m;
}
