# 15 — RMI Activation and Pack200 removed

| | |
|---|---|
| **Category** | Crashes at Runtime |
| **Introduced** | RMI Activation: JDK 17 (JEP 407). Pack200: JDK 14 (JEP 367) |
| **Throws** | `NoClassDefFoundError` |
| **Detect** | `jdeps`; search for `java.rmi.activation`, `java.util.jar.Pack200` |
| **Fix** | Remove the dependency — both were long-unmaintained corners of the platform with no direct replacement API. |
| **Not in the deck.** |

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
