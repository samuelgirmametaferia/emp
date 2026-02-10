# Enums & `match`

Enums are sum types:

```emp
export enum Option {
  None;
  Some(auto);
}
```

## Constructing

- `Option::None`
- `Option::Some(x)`

## Matching

```emp
match o {
  Option::None => { return false; }
  Option::Some(_) => { return true; }
}
```

EMP has tests for exhaustiveness and duplicate arms:

- `tests/ll/enum_match_nonexhaustive_fail.em`
- `tests/ll/enum_match_duplicate_fail.em`
