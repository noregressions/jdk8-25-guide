# 19 — Default GC changed Parallel → G1

| | |
|---|---|
| **Category** | Runs But Wrong (silent behaviour change) |
| **Introduced** | JDK 9 (JEP 248) |
| **Symptom** | Different pause characteristics, throughput, and memory footprint under load — no error, just different numbers |
| **Detect** | JFR recordings comparing GC pause distributions between old and new JDK; or just `-XX:+PrintCommandLineFlags -version`, which is what this test does |
| **Fix** | Re-profile and re-tune under G1 (or explicitly select ZGC/Shenandoah); don't trust JDK 8 performance baselines. |

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
