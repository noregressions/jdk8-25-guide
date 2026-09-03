# 15 — RMI Activation and Pack200 removed

## What this test does

Two independent one-liners, each referencing one of the removed APIs
(`java.rmi.activation.ActivationSystem`, `java.util.jar.Pack200`), compiled once
under JDK 8 and run — unmodified — under both JDK 8 and JDK 25.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
java.rmi.activation.ActivationSystem:
  JDK 8:
    java.rmi.activation.ActivationSystem
    exit=0
  JDK 25 (same .class, no recompile):
    Exception in thread "main" java.lang.NoClassDefFoundError: java/rmi/activation/ActivationSystem
    exit=1

java.util.jar.Pack200:
  JDK 8:
    com.sun.java.util.jar.pack.PackerImpl@6d06d69c
    exit=0
  JDK 25 (same .class, no recompile):
    Exception in thread "main" java.lang.NoClassDefFoundError: java/util/jar/Pack200
    exit=1
```

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–16** java.rmi.activation present (Pack200 went at 14) · **17–26** activation removed too; plain RMI keeps working

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **17**

<!-- matrix:end -->
