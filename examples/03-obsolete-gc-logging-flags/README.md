# 03 — Obsolete GC logging flags

| | |
|---|---|
| **Category** | Won't Start (mostly) |
| **Introduced** | JDK 9 unified logging (JEP 158/271) |
| **Symptom** | Mixed — see finding below. `-XX:+PrintGCTimeStamps` and most of the `PrintGC*` family are startup-fatal on JDK 25. `-XX:+PrintGCDetails` and `-verbose:gc` are **not** fatal — both are kept as deprecated, working aliases that translate to `-Xlog:gc*` under the hood. |
| **Detect** | Audit startup scripts for `-XX:+PrintGC*`; trial-run each specific flag against the target JDK rather than assuming the whole family behaves the same |
| **Fix** | Migrate to `-Xlog:gc*:file=gc.log:time,uptime,level,tags` regardless of which flags currently "work" — even the surviving aliases produce the *new* unified-logging output format, so anything parsing the old text format still breaks. |
| **Finding (not yet reflected in the reference doc)** | The reference doc's item #3 already corrects the deck's claim about `-verbose:gc` (not fatal) but still groups `-XX:+PrintGCDetails` with the fatal `PrintGC*` family. Empirically, `-XX:+PrintGCDetails` is **also** a kept, working, deprecated alias on JDK 25 — same treatment as `-verbose:gc`, not the same treatment as `-XX:+PrintGCTimeStamps`. Worth a follow-up edit to the reference doc: the fatal/non-fatal line doesn't run along "PrintGCDetails + friends vs. verbose:gc" — it runs along which *specific* flag you pick. |

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
