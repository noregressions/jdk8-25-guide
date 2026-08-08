# 22 — Finalisation weakened

| | |
|---|---|
| **Category** | Runs But Wrong (silent, deferred risk) |
| **Introduced** | Deprecated JDK 9; **deprecated for removal JDK 18** (JEP 421) |
| **Symptom** | Resources not cleaned up, or cleaned up at unpredictable times |
| **Detect** | Search for `finalize()` overrides; run with `--finalization=disabled` to test for a hidden dependency |
| **Fix** | `try-with-resources` for deterministic cleanup; `Cleaner` for background cleanup of resources that can't use try-with-resources. |
| **Correction** | The deck's `jdeprscan` sample output shows `finalize()V (forRemoval=true since 9)`. That's wrong — JEP 421 (forRemoval) is JDK 18, not 9. |
| **Finding (not yet reflected in the reference doc)** | The reference doc's own "Detect" column names the flag `-Dfinalization=disabled` — a `-D` system property. That's wrong syntax: the real flag is `--finalization=disabled`, a launcher option (double-dash, no `-D`). Verified below: the `-D` form has zero effect; the `--` form actually disables finalization. |

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
