# 14 — `sun.misc.Unsafe` memory-access methods

| | |
|---|---|
| **Category** | Crashes at Runtime (future) |
| **Introduced** | Deprecated for removal JDK 23 (JEP 471); **warnings began JDK 24** (JEP 498) |
| **Throws** | Warning today; `UnsupportedOperationException` expected in a future release |
| **Detect** | `--sun-misc-unsafe-memory-access=debug` on the test suite; `=deny` in CI to simulate the future default; `jdeps --jdk-internals` |
| **Fix** | Migrate to `VarHandle` or the Foreign Function & Memory API. Usage is almost always in a dependency (Guava, Maven, JavaFX, OpenTelemetry), not your own code. |
| **Correction** | The deck's slide says "Runtime warnings (JDK 25)." The written series (`nineteen-ways`) already has this right — JEP 498 is JDK 24. Fix the deck to match the article. |

## What this test does

Uses reflection to grab the `Unsafe` singleton and calls `objectFieldOffset` +
`putInt` — the exact memory-access pattern flagged by JEP 498. Runs three ways:
JDK 8 (nothing), JDK 25 default (a one-time deprecation warning, still works),
and JDK 25 with `--sun-misc-unsafe-memory-access=deny` — a flag that lets you
preview the *future* default (hard failure) today, in CI, without waiting for the
release that actually ships it.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8:
  h.x via Unsafe = 42
  exit=0

JDK 25 (default):
  WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
  WARNING: sun.misc.Unsafe::objectFieldOffset has been called by UnsafeTest (file:...)
  WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
  h.x via Unsafe = 42
  exit=0

JDK 25 with --sun-misc-unsafe-memory-access=deny (simulating the future default):
  Exception in thread "main" java.lang.UnsupportedOperationException: objectFieldOffset
      at jdk.unsupported/sun.misc.Unsafe.beforeMemoryAccessSlow(Unsafe.java:1822)
      at jdk.unsupported/sun.misc.Unsafe.objectFieldOffset(Unsafe.java:905)
      at UnsafeTest.main(UnsafeTest.java:8)
  exit=1
```
