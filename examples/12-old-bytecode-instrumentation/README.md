# 12 — Old bytecode instrumentation libraries

## What this test does — and how it approximates the real failure

There's no ASM/ByteBuddy dependency vendored into this test harness, so this test
demonstrates the underlying mechanism directly rather than through a specific
library: it compiles the same trivial class with JDK 8 and JDK 25, confirms the
class file major version really did change (52 → 69), then runs the JDK-25-compiled
`.class` file with JDK 8's `java` launcher. JDK 8's class loader rejecting a
newer-major-version class file is the exact same code path an old ASM/ByteBuddy
bytecode reader takes internally when it encounters a major version number it
doesn't recognize — the message differs (library code usually wraps it as its own
`IllegalArgumentException`) but the root cause and trigger condition are identical.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8  compiled class file major version: 52
JDK 25 compiled class file major version: 69
Loading the JDK-25-compiled class file with JDK 8's JVM:
  Error: A JNI error has occurred, please check your installation and try again
  Exception in thread "main" java.lang.UnsupportedClassVersionError: Simple has
  been compiled by a more recent version of the Java Runtime (class file version
  69.0), this version of the Java Runtime only recognizes class file versions up
  to 52.0
  exit=1
```

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | P | . |

**What the JDK does, release by release:**

**8–24** class-file major version below 69 · **25** version 69 · **26** version 70 -- the number moves every release, so any pinned reader expires

**Shape:** **window** — arrives, then stops: the API this test needs was removed later, so the difference can no longer be expressed · first differs at **25**, reverts at **26**

Passes only at 25 because the test asserts class-file version 69 exactly. JDK 26 emits 70, so the row flips at 26 — the mechanism is continuous, not a boundary, and the assertion should track the running JDK rather than a literal.

<!-- matrix:end -->
