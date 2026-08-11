# 27 — `java.lang.IO` and `java.lang.Record` collisions

**Full details:** [Chapter 3.27 — java.lang.IO and java.lang.Record Collisions](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.27-java-lang-io-record-collision.md)

## What this test does

A user-defined `mypkg.IO` class, referenced from another package three ways:
wildcard import (`import mypkg.*`), explicit single-type import (`import mypkg.IO`),
and — as a control — the same wildcard import compiled under JDK 8, where
`java.lang.IO` doesn't exist yet. Repeats the identical setup for `mypkg.Record`
against `java.lang.Record` (JDK 16, one cycle earlier) to confirm this is a
recurring pattern, not IO-specific.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 25, wildcard import (import mypkg.*):
  UseWildcard.java:5: error: reference to IO is ambiguous
      IO.hello();
      ^
    both class mypkg.IO in mypkg and class java.lang.IO in java.lang match
  exit=1

JDK 25, explicit single-type import (import mypkg.IO):
  exit=0

JDK 8, wildcard import (java.lang.IO doesn't exist yet -- control):
  exit=0

JDK 25, wildcard import, SAME collision pattern with java.lang.Record (JEP 395, JDK 16):
  UseWildcardRecord.java:9: error: reference to Record is ambiguous
      Record.hello();
      ^
    both class mypkg.Record in mypkg and class java.lang.Record in java.lang match
  exit=1
```

Real-world relevance: `IO` and `Record` are both short, generic, commonly-picked
names (I/O utility classes, data-record wrapper classes) — exactly the kind of
class name a large codebase is statistically likely to have used somewhere, and
exactly the kind of file that's reached via a wildcard import from an old,
never-touched utility package.
