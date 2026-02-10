# Modules & Packages

## Modules

EMP uses explicit imports with `use` items.

As implemented in the parser, supported import forms include:

- `use {a, b as c} from foo.bar;`
- `use * from foo.bar;`
- `use foo.bar::*;`
- `use foo.bar::{a, b as c};`

There is also an allow-private marker:

- `use @ {a, b} from foo.bar;`

(`@` appears immediately after `use`.)

Concrete examples:

```emp
use * from std.console;
use {print, println as pl} from std.console;
use std.console::*;
use std.console::{print, println as pl};
```

## Bundled stdlib

The compiler can resolve bundled modules from:

- `stdlib/emp_mods/*`

When you import `std/*`, EMP can auto-vendor those modules into your project’s `emp_mods/`.

See ../stdlib/emp_mods/README.md.

## Packages (draft)

See ../PKG.md for the proposed package layout and resolution order.
