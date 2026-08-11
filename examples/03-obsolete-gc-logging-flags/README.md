# 03 — Obsolete GC logging flags

**Full details:** [Chapter 3.3 — Obsolete GC Logging Flags](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.03-obsolete-gc-logging-flags.md)

## What this test does

Runs `-version` under both JDKs with three different flags and compares exit codes
and stderr for each: `-XX:+PrintGCDetails`, `-XX:+PrintGCTimeStamps`, `-verbose:gc`.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
-XX:+PrintGCDetails:
  JDK8  -XX:+PrintGCDetails -> exit=0
    openjdk version "1.8.0_502"
  JDK25 -XX:+PrintGCDetails -> exit=0
    [0.001s][warning][gc] -XX:+PrintGCDetails is deprecated. Will use -Xlog:gc* instead.

-XX:+PrintGCTimeStamps:
  JDK8  -XX:+PrintGCTimeStamps -> exit=0
    openjdk version "1.8.0_502"
  JDK25 -XX:+PrintGCTimeStamps -> exit=1
    Unrecognized VM option 'PrintGCTimeStamps'

-verbose:gc:
  JDK8  -verbose:gc -> exit=0
  JDK25 -verbose:gc -> exit=0
    [0.005s][info][gc] Using G1
```

Same lesson as test 18 (UTF-8 charset): don't trust a category-level claim without
trying the *specific* flag your own scripts actually use. `PrintGCDetails` and
`PrintGCTimeStamps` sound like siblings and are documented in the same "PrintGC*
family" sentence in most migration write-ups (including this repo's own reference
doc before this test was built) -- but only one of them is actually startup-fatal.
