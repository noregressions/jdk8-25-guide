# 10 — `Thread.stop()` / `suspend()` / `resume()` throw

**Full details:** [Chapter 3.10 — Thread.stop(), suspend() and resume() Throw](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.10-thread-stop-suspend-resume.md)

## What this test does

Starts a thread, sleeps briefly, then calls `.stop()` on it.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8:
  stop() returned normally
  exit=0

JDK 25:
  Exception in thread "main" java.lang.UnsupportedOperationException
      at java.base/java.lang.Thread.stop(Thread.java:1557)
      at StopTest.main(StopTest.java:6)
  exit=1
```
