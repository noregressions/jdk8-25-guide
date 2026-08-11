# 30 — Stricter `javac` breaks `-Werror` builds

**Full details:** [Chapter 3.30 — Stricter javac Breaks -Werror Builds](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.30-stricter-javac-werror.md)

## What this test does

`ThisEscape`'s constructor calls an overridable instance method — `Sub`
overrides that method to read one of its own fields, demonstrating *why* this is
a real risk, not just a lint false-positive: the override can run before `Sub`'s
own state is set up. Compiles the identical two files with `-Xlint:all -Werror`
under both JDKs.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8, -Xlint:all -Werror:
  exit=0

JDK 25, -Xlint:all -Werror (identical source, identical flags):
  ThisEscape.java:9: warning: [this-escape] possible 'this' escape before subclass is fully initialized
          doSomething();
                     ^
  error: warnings found and -Werror specified
  1 error
  1 warning
  exit=1
```

This is the general shape of item 30, not specific to `this-escape` — any of the
dozens of lint categories added across JDK 9-25 can do the same thing to an
`-Werror` build that's never been trial-compiled against the target JDK before
cutting the migration branch.
