# 22 — Finalisation weakened

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
fragile "still works" is for code that depends on it. It also pins the flag
syntax, which is easy to get wrong in a way that fails silently.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8:
  finalized = true

JDK 25 (default -- finalization still enabled, still works):
  finalized = true

JDK 25 with --finalization=disabled (the actual flag; -D does NOT work):
  finalized = false

JDK 25 with -Dfinalization=disabled (the system-property spelling, as a control -- should NOT disable it):
  finalized = true
```

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–17** finalize() runs, with no way to turn it off · **18–26** terminally deprecated and --finalization=disabled ships, so its absence is rehearsable

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **18**

<!-- matrix:end -->
