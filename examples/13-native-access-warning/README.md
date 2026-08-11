# 13 — Native access without `--enable-native-access`

**Full details:** [Chapter 3.13 — Native Access Without --enable-native-access](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.13-native-access-warning.md)

## What this test does — and its limit

Downcalls `libc`'s `strlen` via the Foreign Function & Memory API, once without
`--enable-native-access` and once with it. **This is a JDK-25-only comparison** —
the FFM API is a JDK 22+ concept, so there's no JDK 8 side to run (JDK 8 native
access meant hand-written JNI, a different mechanism entirely with no equivalent
warning system). The real migration checkpoint here is JDK 22-24 → 25 (or 25 →
whichever future release turns this into a hard error), not 8 → 25 directly.

**This test cannot demonstrate the eventual hard failure** — the doc's own symptom
line says "warning today; hard error on a future release," and that future release
doesn't exist yet on JDK 25. Treat a PASS here as "the warning path still fires as
documented," not as proof the eventual break is real — that part is a forward-looking
claim about a release that hasn't shipped.

## Verified output (sandbox, Temurin 25.0.4)

```
JDK 25, without --enable-native-access:
  WARNING: A restricted method in java.lang.foreign.Linker has been called
  WARNING: java.lang.foreign.Linker::downcallHandle has been called by Native in an unnamed module (file:...)
  WARNING: Use --enable-native-access=ALL-UNNAMED to avoid a warning for callers in this module
  WARNING: Restricted methods will be blocked in a future release unless native access is enabled
  strlen(hello) = 5
  exit=0

JDK 25, with --enable-native-access=ALL-UNNAMED:
  strlen(hello) = 5
  exit=0
```
