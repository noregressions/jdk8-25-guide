# 19 — Default GC changed Parallel → G1

**Full details:** [Chapter 3.19 — The Default Garbage Collector Changed](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.19-default-gc-parallel-to-g1.md)

## What this test does — and its limit

Runs `-version` with `-XX:+PrintCommandLineFlags` under both JDKs with no explicit
GC selection, and checks which collector each JVM picked for itself.

**This test does not attempt to measure the actual throughput/pause-time
difference** — that's real, but it depends on heap size, allocation rate, and
object lifetime patterns in a way a portable, deterministic pass/fail script
can't responsibly assert on. What's checked here is the one part that's fully
deterministic and directly supports the doc's claim: the collector selection
itself silently changes with zero configuration change.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8 default GC-related flags:
  -XX:+UseParallelGC

JDK 25 default GC-related flags:
  -XX:+UseG1GC
```
