# 27 — `java.lang.IO` and `java.lang.Record` collisions

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

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | P | P |

**What the JDK does, release by release:**

**8–24** no java.lang.IO, so a user class named IO is unambiguous · **25–26** java.lang.IO exists and collides through wildcard imports only

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **25**

<!-- matrix:end -->
