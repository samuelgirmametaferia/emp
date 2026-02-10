// std.path
// Path manipulation utilities.

// Windows separator
let SEP: u8 = 92; // '\\'
let ALT_SEP: u8 = 47; // '/'

export fn pathIsSep(c: u8) -> bool {
    if c == SEP { return true; }
    if c == ALT_SEP { return true; }
    return false;
}

export fn pathJoin(a: u8[], b: u8[]) -> u8[] {
    let out: u8[];

    // Copy a
    let i: i32 = 0;
    while i < (i32)a.len() {
        out.push(a[i]);
        i = i + 1;
    }

    // Add separator if needed
    if out.len() > 0 {
        let last: u8 = out[out.len() - 1];
        if !pathIsSep(last) {
            out.push(SEP);
        }
    }

    // Copy b
    let j: i32 = 0;
    while j < (i32)b.len() {
        out.push(b[j]);
        j = j + 1;
    }

    return out;
}

export fn pathParent(path: u8[]) -> u8[] {
    let len: i32 = (i32)path.len();
    if len == 0 { return path; }

    // Trim trailing separators
    let end: i32 = len - 1;
    while end > 0 {
        let c: u8 = path[end];
        if !pathIsSep(c) {
             break;
        }
        end = end - 1;
    }

    // Find next separator from end
    while end >= 0 {
        let c: u8 = path[end];
        if pathIsSep(c) {
            break;
        }
        end = end - 1;
    }

    if end < 0 {
        let empty: u8[];
        return empty;
    }

    let out: u8[];
    let i: i32 = 0;
    while i < end {
        out.push(path[i]);
        i = i + 1;
    }
    return out;
}

export fn pathExtension(path: u8[]) -> u8[] {
    let len: i32 = (i32)path.len();
    let i: i32 = len - 1;
    while i >= 0 {
        let c: u8 = path[i];
        if pathIsSep(c) {
            let empty: u8[];
            return empty;
        }
        if c == 46 { // '.'
            let out: u8[];
            let k: i32 = i + 1;
            while k < len {
                out.push(path[k]);
                k = k + 1;
            }
            return out;
        }
        i = i - 1;
    }
    let empty: u8[];
    return empty;
}
