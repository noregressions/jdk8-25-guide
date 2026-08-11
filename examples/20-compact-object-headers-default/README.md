# 20 — Compact object headers break cached field offsets

**Full details:** [Chapter 3.20 — Compact Object Headers Break Cached Field Offsets](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.20-compact-object-headers.md)

## What this test does — and its limit

This is a JDK-25-only check: `UseCompactObjectHeaders` doesn't exist as a flag on
JDK 8 (the option itself is new in 25), so there's no cross-version comparison to
run. What's verified here is narrower but load-bearing: the actual shipped default
value of the flag, since that's specifically what the deck and `guide.pdf` get
wrong.

**This test does not reproduce the actual heap-corruption failure mode** — that
requires code that caches a raw `Unsafe.objectFieldOffset()` value and reuses it
across GC-driven object layout changes with the flag *enabled*, which is a fragile,
timing-sensitive scenario not suited to a deterministic pass/fail check. What's
checked instead is the fact this whole item hinges on: that the feature ships
**off** by default, so it's not a day-one risk for most teams — contrary to what
the deck's slide implies.

## Verified output (sandbox, Temurin 25.0.4)

```
JDK 25 -XX:+PrintFlagsFinal | grep UseCompactObjectHeaders:
  bool UseCompactObjectHeaders = false {product lp64_product} {default}
shipped default value: false
```
