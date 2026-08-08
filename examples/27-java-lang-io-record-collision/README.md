# 27 — `java.lang.IO` and `java.lang.Record` collisions

| | |
|---|---|
| **Category** | Recompilation Surprises |
| **Introduced** | `java.lang.IO`: JDK 25 (JEP 512). `java.lang.Record`: JDK 16 (JEP 395 — Records) |
| **Throws** | Ambiguous-reference compile error on recompilation |
| **Detect** | Compile against the target JDK — it names both candidate classes |
| **Fix** | Rename the class, or use an explicit single-type import to disambiguate. |
| **Correction** | Narrower than "any class named `IO` breaks": it only bites when the name is reached via a **wildcard import** from another package. Same-package references and explicit single-type imports still resolve correctly. `java.lang.Record` caused the identical breakage wave a JDK cycle earlier — worth treating as one pattern, not two unrelated incidents. |

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
