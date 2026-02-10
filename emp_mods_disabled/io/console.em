use {cPrint} from emp_mods.platform.c;

// Safe wrapper: users can call this without `@emp off`.
export fn print(msg: auto) {
  @emp off {
    cPrint(msg);
  }
}

export fn println(msg: auto) {
  @emp off {
    cPrint(msg);
    cPrint("\n");
  }
}
