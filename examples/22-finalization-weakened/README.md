# 22 — Finalisation weakened

**Full details:** [Chapter 3.22 — Finalisation Weakened](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.22-finalisation-weakened.md)

## What this test does — and why it doesn't try to prove "unpredictable timing"

`finalize()` still runs, identically, on both JDK 8 and JDK 25 today — it's
deprecated for removal, not yet removed. A same-result comparison across JDKs is
the *correct* outcome here, not a gap in the test. What this item is really about
is that any code relying on finalization is one JDK-default-flip away from silent
breakage, and finalization's inherent non-determinism (it runs on a GC-triggered
background thread, on no fixed schedule) makes "cleaned up at unpredictable times"
unsuitable for a deterministic pass/fail assertion in the first place — a flaky
test asserting on GC timing would be worse than no test.

What's fully deterministic and worth checking instead: finalization can be turned
off completely, right now, with a documented flag — demonstrating exactly how
fragile "still works" is for code that depends on it. Along the way, this test
caught a flag-syntax bug in the reference doc itself.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8:
  finalized = true

JDK 25 (default -- finalization still enabled, still works):
  finalized = true

JDK 25 with --finalization=disabled (the actual flag; -D does NOT work):
  finalized = false

JDK 25 with -Dfinalization=disabled (the doc's stated flag, as a control -- should NOT disable it):
  finalized = true
```
