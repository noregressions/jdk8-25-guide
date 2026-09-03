# 20 — Compact object headers break cached field offsets

## What this test does — and its limit

This is a JDK-25-only check: `UseCompactObjectHeaders` doesn't exist as a flag on
JDK 8 (the option itself is new in 25), so there's no cross-version comparison to
run. What's verified here is narrower but load-bearing: the actual shipped default
value of the flag, read from the JVM's own flag table rather than from release
notes, because the entire risk profile of this item depends on it.

**This test does not reproduce the actual heap-corruption failure mode** — that
requires code that caches a raw `Unsafe.objectFieldOffset()` value and reuses it
across GC-driven object layout changes with the flag *enabled*, which is a fragile,
timing-sensitive scenario not suited to a deterministic pass/fail check. What's
checked instead is the fact this whole item hinges on: that the feature ships
**off** by default, so it's not a day-one risk for most teams. It's a day-*two*
risk, and the trigger is someone turning the flag on for its very real benefits.

## Verified output (sandbox, Temurin 25.0.4)

```
JDK 25 -XX:+PrintFlagsFinal | grep UseCompactObjectHeaders:
  bool UseCompactObjectHeaders = false {product lp64_product} {default}
shipped default value: false
```

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | P | P |

**What the JDK does, release by release:**

**8–24** no such option · **25–26** UseCompactObjectHeaders ships as a product option, off by default

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **25**

<!-- matrix:end -->
