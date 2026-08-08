# 21 — ThreadGroup degradation

| | |
|---|---|
| **Category** | Runs But Wrong (mostly) / Crashes at Runtime (partly) |
| **Introduced** | Spans JDK 14–20; no single JEP |
| **Symptom** | `destroy()` a no-op since JDK 16; `stop()`/`suspend()`/`resume()` throw since JDK 20; daemon status ignored since JDK 16 |
| **Detect** | Search for `ThreadGroup.destroy()`, `ThreadGroup.stop()`, daemon thread-group usage |
| **Fix** | Move lifecycle management to `ExecutorService` and explicit thread tracking; there's no drop-in replacement for `ThreadGroup`'s old behaviour. |
| **Finding (not yet reflected in the reference doc)** | The doc's single sentence — "`stop()`/`suspend()`/`resume()` throw since JDK 20" — describes `Thread`'s equivalent methods (test 10) accurately, but not `ThreadGroup`'s. Empirically, `ThreadGroup.stop()` isn't just made to throw; it's been **removed from the class entirely** — old, already-compiled bytecode calling it gets `NoSuchMethodError`, and it no longer even compiles as a call target. That's a harder failure than "throws `UnsupportedOperationException`," and worth a follow-up correction distinguishing `Thread`'s degradation (throws) from `ThreadGroup`'s (removed). |

## What this test does

Two independent checks, because the two methods degrade differently: `stop()`
(compiled once under JDK 8, then run unmodified against both JDK 8 and JDK 25 —
it doesn't even compile under 25 anymore, so this test can't recompile it there),
and `destroy()` (compiles and runs fine on both, but only actually destroys the
group on JDK 8).

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
-- ThreadGroup.stop(), JDK-8-compiled class, run on JDK 8: --
  tg.stop() returned normally

-- ThreadGroup.stop(), SAME JDK-8-compiled class, run on JDK 25 (no recompile): --
  tg.stop() threw: java.lang.NoSuchMethodError: 'void java.lang.ThreadGroup.stop()'

-- ThreadGroup.destroy(), JDK 8: --
  isDestroyed() before = false
  destroy() returned normally, isDestroyed() after = true

-- ThreadGroup.destroy(), JDK 25: --
  isDestroyed() before = false
  destroy() returned normally, isDestroyed() after = false
```
