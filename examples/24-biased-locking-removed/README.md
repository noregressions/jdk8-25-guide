# 24 — Biased locking disabled and removed

**Full details:** [Chapter 3.24 — Biased Locking Disabled and Removed](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.24-biased-locking-removed.md)

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
