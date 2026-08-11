# 21 — ThreadGroup degradation

**Full details:** [Chapter 3.21 — ThreadGroup Degradation](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.21-threadgroup-degradation.md)

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
