# 24 — Biased locking disabled and removed

## What this test does — and why it doesn't try to measure throughput

Runs an uncontended `synchronized` loop under four configurations: JDK 8 default,
JDK 8 with `-XX:+UseBiasedLocking` explicit, JDK 25 default, JDK 25 with the same
explicit flag. **This test does not assert on timing** — an uncontended-lock
throughput delta is real, but sensitive enough to sandbox CPU noise that a
hard-coded "must be N% faster" check would be flaky rather than informative. What's
fully deterministic and checked instead: whether each configuration starts at all.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8, default (no explicit biased-locking flag):
  uncontended synchronized loop completed, counter=2000000
  exit=0

JDK 8, with -XX:+UseBiasedLocking explicitly (a common JDK-8-era tuning flag):
  uncontended synchronized loop completed, counter=2000000
  exit=0

JDK 25, default (no explicit biased-locking flag):
  uncontended synchronized loop completed, counter=2000000
  exit=0

JDK 25, with the SAME explicit -XX:+UseBiasedLocking flag carried forward from the JDK 8 config:
  Unrecognized VM option 'UseBiasedLocking'
  Error: Could not create the Java Virtual Machine.
  exit=1
```

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–18** biased locking available (off by default from 15) · **19–26** flag expired: -XX:+UseBiasedLocking is unrecognised and startup-fatal

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **19**

<!-- matrix:end -->
