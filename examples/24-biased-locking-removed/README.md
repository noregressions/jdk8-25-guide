# 24 — Biased locking disabled and removed

| | |
|---|---|
| **Category** | Runs But Wrong *(without the explicit flag)* — but see finding below |
| **Introduced** | ⚠ JEP 374 — Deprecate and Disable Biased Locking (disabled by default JDK 15); full removal timeline less precisely documented |
| **Symptom** | No error — a throughput regression in legacy code with heavy uncontended synchronization |
| **Detect** | JFR baseline comparison — thread contention and throughput deltas between JDK 8 and JDK 25 |
| **Fix** | None needed for correctness; if throughput matters, profile and consider modern concurrent collections. |
| **Not in the deck.** |
| **Finding (not yet reflected in the reference doc)** | The doc's Symptom line — "No error, a throughput regression" — is only true for code that *doesn't* explicitly request biased locking. A meaningful share of JDK-8-era production configs **do** carry `-XX:+UseBiasedLocking` explicitly (it was a standard tuning recommendation for lock-heavy workloads for years). For those configs specifically, this is a **Won't Start** failure on JDK 25 (`Unrecognized VM option`), not a silent regression at all — the flag was fully removed at some point after JEP 374 disabled it by default, and this sandbox's Temurin 25.0.4 rejects it outright. Worth re-categorizing or at least footnoting: "no error" is conditional on not having the old tuning flag lying around in a startup script." |

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
