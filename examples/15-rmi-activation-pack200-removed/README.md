# 15 — RMI Activation and Pack200 removed

**Full details:** [Chapter 3.15 — RMI Activation and Pack200 Removed](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.15-rmi-activation-pack200-removed.md)

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
