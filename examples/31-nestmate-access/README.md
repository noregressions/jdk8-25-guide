# 31 — Nestmate access — "the one that helps"

**Full details:** [Chapter 3.31 — Nestmate Access — the One That Helps](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.31-nestmate-access.md)

## What this test does

`Outer`'s private field is read from a nested static class `Inner`. Compiles
under both JDKs and inspects the class file for the synthetic `access$000`
bridge method (javac8's mechanism) vs. `NestHost`/`NestMembers` attributes
(javac25's mechanism), plus raw `.class` file size. Behaviour is identical
either way — that's the "helps" part.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
Behaviour, JDK 8:
  secret via Inner = 42
Behaviour, JDK 25:
  secret via Inner = 42

javac8-compiled Outer.class:  access$ bridge methods=1, NestHost/NestMembers attrs=0, size=853B
javac25-compiled Outer.class: access$ bridge methods=0, NestHost/NestMembers attrs=2, size=1023B
```

Note the size went **up**, not down, for this particular tiny class — the
`NestMembers` attribute lists every nestmate by name in the constant pool, which
has its own overhead that a single-method-removal doesn't necessarily offset.
The real, reliable win here is cleaner stack traces (no `access$000` frame
showing up in a debugger or exception trace) and one fewer synthetic method for
tools like test 12's bytecode instrumentation libraries to trip over — not
necessarily smaller files across the board.
