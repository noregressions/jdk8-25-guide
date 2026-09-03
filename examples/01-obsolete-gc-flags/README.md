# 01 — Obsolete GC flags

## What this test does

Runs `java -XX:+UseConcMarkSweepGC -version` on both JDKs and checks the exit code.
On JDK 8 the flag is accepted (CMS is a supported collector). On JDK 25 the JVM refuses
to start at all — this is the "nothing else matters until the JVM launches" category.

## Verified output (2026-08-07, Temurin 8u502 / Temurin 25.0.4)

```
$ java8 -XX:+UseConcMarkSweepGC -version
openjdk version "1.8.0_502"
OpenJDK Runtime Environment (Temurin)(build 1.8.0_502-b07)
OpenJDK 64-Bit Server VM (Temurin)(build 25.502-b07, mixed mode)
exit code: 0

$ java25 -XX:+UseConcMarkSweepGC -version
Unrecognized VM option 'UseConcMarkSweepGC'
Error: Could not create the Java Virtual Machine.
Error: A fatal exception has occurred. Program will exit.
exit code: 1
```

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–14** CMS collector present, -XX:+UseConcMarkSweepGC accepted · **15–26** flag expired: unrecognised, VM refuses to start

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **15**

<!-- matrix:end -->
