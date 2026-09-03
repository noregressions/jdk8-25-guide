# 11 — Split packages on the module path

## What this test does — and why there's no JDK 8 side

The module system is a JDK 9+ concept, so unlike most tests here there's no
"worked on JDK 8, breaks on JDK 25" story with the *same* JVM flag. Instead this
compares two JDK 25 runs of the identical split-package setup (`com.example` defined
in both `modA` and `modB`): once via `-cp` (still works, silently — the exact
behaviour JDK 8 always had, since it never had a module path to enforce anything),
once via `--module-path` (hard failure at boot-layer construction).

## Verified output (sandbox, Temurin 25.0.4)

```
JDK 25, classpath (package split across two JARs, same as JDK 8 behaviour):
  openjdk version "25.0.4" 2026-07-21 LTS
  ...
  exit=0

JDK 25, module path (same two packages, same classes):
  Error occurred during initialization of boot layer
  java.lang.LayerInstantiationException: Package com.example in both module modA and module modB
  exit=1
```

The practical risk: a team migrating an old multi-JAR app to the module system
(for a `jlink` custom runtime, say) can hit this even though the exact same JARs
ran for years on the classpath without incident.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8** no module path exists, so split packages are only ever a classpath non-issue · **9–26** same package in two modules is a LayerInstantiationException at boot

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **9**

<!-- matrix:end -->
