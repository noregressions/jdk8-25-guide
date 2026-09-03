# 10 — `Thread.stop()` / `suspend()` / `resume()` throw

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

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | P | P | P | P | P | P | . |

**What the JDK does, release by release:**

**8–19** Thread.stop() works, killing the thread and releasing its monitors · **20–25** degraded: throws UnsupportedOperationException, which a catch block can still swallow · **26** method removed: old bytecode gets NoSuchMethodError, and no catch sees it

**Shape:** **window** — arrives, then stops: the API this test needs was removed later, so the difference can no longer be expressed · first differs at **20**, reverts at **26**

Two-stage, and the matrix shows both stages: the exception appears at 20 and holds through 25, then the row flips back at 26 because `Thread.stop` was removed outright — old bytecode gets `NoSuchMethodError` there, which no `catch (UnsupportedOperationException)` will see.

<!-- matrix:end -->
