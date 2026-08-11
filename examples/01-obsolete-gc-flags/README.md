# 01 — Obsolete GC flags

**Full details:** [Chapter 3.1 — Obsolete GC Flags](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.01-obsolete-gc-flags.md)

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
