// std.path (minimal)
// Only what the benchmark needs.

fn pathIsSep(c: u8) -> bool {
    if c == 92 { return true; } // '\\'
    if c == 47 { return true; } // '/'
    return false;
}

export fn pathJoin(a: u8[], b: u8[]) -> u8[] {
    let out: u8[];

    let i: i32 = 0;
    while i < a.len() {
        out.push(a[i]);
        i = i + 1;
    }

    if out.len() > 0 {
        let last: u8 = out[out.len() - 1];
        if !pathIsSep(last) { out.push(92); }
    }

    let j: i32 = 0;
    while j < b.len() {
        out.push(b[j]);
        j = j + 1;
    }

    return out;
}
