# 10 — `Thread.stop()` / `suspend()` / `resume()` throw

| | |
|---|---|
| **Category** | Crashes at Runtime |
| **Introduced** | ⚠ JDK 20 (no dedicated JEP — implementation change to long-deprecated methods, distinct from the `ThreadGroup` item, test 21) |
| **Throws** | `UnsupportedOperationException` |
| **Detect** | `jdeprscan --for-removal`; search for `.stop()`/`.suspend()`/`.resume()` on `Thread` |
| **Fix** | Interruption + cooperative cancellation (`Thread.interrupt()`, a shared `volatile` flag, or `ExecutorService.shutdown()`). |
| **Not in the deck** — which only covers the `ThreadGroup`-level siblings of these same methods, a separate API surface (see test 21). |

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
