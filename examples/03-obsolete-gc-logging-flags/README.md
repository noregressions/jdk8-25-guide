# 03 — Obsolete GC logging flags

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

## Added check: `-Xloggc`, the fourth flag

Any grep for GC logging turns up four flags, not three. `-Xloggc:<file>` belongs in
the survivors column with `-verbose:gc` and `PrintGCDetails`:

```
-Xloggc:<file>:
  JDK8  -Xloggc:gclogs/gc8.log  -> exit=0
  JDK25 -Xloggc:gclogs/gc25.log -> exit=0
    [0.001s][warning][gc] -Xloggc is deprecated. Will use -Xlog:gc:gclogs/gc25.log instead.
```

So the tally across the four flags a realistic config carries is three survivors and
one fatal — and nothing in the names indicates which is which. `PrintGCTimeStamps` is
the one that stops the JVM; `PrintGCDetails`, `-verbose:gc` and `-Xloggc` all
translate themselves and carry on.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8** PrintGC* family all accepted · **9–26** unified logging: PrintGCTimeStamps fatal, PrintGCDetails/-verbose:gc/-Xloggc kept as warning aliases

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **9**

<!-- matrix:end -->
