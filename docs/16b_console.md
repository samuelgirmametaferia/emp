# Console

`std.console` provides Windows console I/O.

## Basic output

- `write`, `writeLine`
- `writeString`, `writeLineString`
- `writeError*` variants

## Animations

Animations are just repeated writes to the same line using `\r`.

New helpers:

- `sleepMillis(ms)`
- `carriageReturn()`
- `spinnerFrame(tick)`
- `spinnerStep(&mut tick, label)`
- `progressBar(current, total, width)`

Example:

```emp
use {spinnerStep, progressBar, sleepMillis, writeLine} from std.console;

fn main() {
  let tick: i32 = 0;
  for i in 0...50 {
    spinnerStep(&mut tick, "working...");
    progressBar(i, 50, 20);
    sleepMillis(30);
  }
  writeLine("\nDone");
}
```

## Markdown output

`std.consoleMd` writes Markdown-formatted text to stdout (it does not render Markdown in the console).

- `mdHeading(level, text)`
- `mdBullet(text)`
- `mdCodeBlock(lang, code)`
