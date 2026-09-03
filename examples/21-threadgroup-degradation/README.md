# 21 — ThreadGroup degradation

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

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | P | P | P | P |

**What the JDK does, release by release:**

**8–22** ThreadGroup lifecycle methods present and working (destroy a no-op from 16) · **23–26** stop/suspend/resume removed outright; destroy/isDestroyed/setDaemon survive as no-ops

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **23**

<!-- matrix:end -->
