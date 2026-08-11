# 12 — Old bytecode instrumentation libraries

**Full details:** [Chapter 3.12 — Old Bytecode Instrumentation Libraries](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.12-old-bytecode-instrumentation.md)

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
