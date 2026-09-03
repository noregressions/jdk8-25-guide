# 14 — `sun.misc.Unsafe` memory-access methods

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

## Added check: how coarse is the default warning?

`UnsafeGranularity.java` has four Unsafe call sites — one `objectFieldOffset` plus
three `putInt` — spread across three classes. If the warning fired per call site,
which is the natural assumption, that would be four warnings.

```
JDK 25 default (warn) -- 4 Unsafe call sites across 3 classes:
  WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
  WARNING: sun.misc.Unsafe::objectFieldOffset has been called by UnsafeGranularity (file:...)
  WARNING: Please consider reporting this to the maintainers of class UnsafeGranularity
  WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
  3 distinct putInt call sites across 2 classes, final h.x = 3

JDK 25 with --sun-misc-unsafe-memory-access=debug -- same 4 call sites:
  WARNING: sun.misc.Unsafe::objectFieldOffset called by UnsafeGranularity (file:...)
  	at UnsafeGranularity.main(UnsafeGranularity.java:36)
  WARNING: sun.misc.Unsafe::putInt called by UnsafeGranularity$SiteA (file:...)
  	at UnsafeGranularity$SiteA.first(UnsafeGranularity.java:26)
  WARNING: sun.misc.Unsafe::putInt called by UnsafeGranularity$SiteA (file:...)
  	at UnsafeGranularity$SiteA.second(UnsafeGranularity.java:27)
  WARNING: sun.misc.Unsafe::putInt called by UnsafeGranularity$SiteB (file:...)
  	at UnsafeGranularity$SiteB.only(UnsafeGranularity.java:31)

warning blocks under the default (warn) ....... 1
call sites located under =debug ............... 4
```

**One** warning block for the entire JVM run — not per call site, not even per
calling class — naming only whichever memory-access method happened to run first.
The three `putInt` sites are never mentioned.

This matters because warning count is what people reach for when judging how much
`Unsafe` a codebase has left, and it measures nothing of the sort: a class with
fifty `Unsafe` call sites warns exactly once, and so does a class with one. Only
`=debug` produces an inventory.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | P | P | P |

**What the JDK does, release by release:**

**8–23** sun.misc.Unsafe memory access is silent (terminally deprecated at 23) · **24–26** warns once per JVM run; --sun-misc-unsafe-memory-access=deny previews the future throw

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **24**

<!-- matrix:end -->
