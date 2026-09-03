# 19 — Default GC changed Parallel → G1

## What this test does — and its limit

Runs `-version` with `-XX:+PrintCommandLineFlags` under both JDKs with no explicit
GC selection, and checks which collector each JVM picked for itself.

**This test does not attempt to measure the actual throughput/pause-time
difference** — that's real, but it depends on heap size, allocation rate, and
object lifetime patterns in a way a portable, deterministic pass/fail script
can't responsibly assert on. What's checked here is the one part that's fully
deterministic and it is the whole point of the item: the collector selection
itself silently changes with zero configuration change.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8 default GC-related flags:
  -XX:+UseParallelGC

JDK 25 default GC-related flags:
  -XX:+UseG1GC
```

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8** Parallel GC chosen by default · **9–26** G1 chosen by default: different pause, throughput and footprint profile

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **9**

<!-- matrix:end -->
