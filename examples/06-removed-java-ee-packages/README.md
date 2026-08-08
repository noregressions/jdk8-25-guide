# 06 — Removed Java EE packages

| | |
|---|---|
| **Category** | Crashes at Runtime |
| **Introduced** | JDK 11 (JEP 320) |
| **Throws** | `NoClassDefFoundError`, `ClassNotFoundException` |
| **Detect** | `jdeprscan --for-removal`; compile against JDK 11+ |
| **Fix** | Add Jakarta EE coordinates explicitly (`jakarta.xml.bind-api`, etc.) — the classes were removed, not renamed automatically. |

## What this test does

Compiles and runs a one-liner referencing `javax.xml.bind.annotation.XmlRootElement`
(JAXB) under JDK 8, where it's bundled in the runtime. Then runs the **same class
file** — no recompile — under JDK 25, where the JDK no longer ships that package at
all.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8:
  javax.xml.bind.annotation.XmlRootElement
  exit=0

JDK 25 (same .class file, no recompile):
  Exception in thread "main" java.lang.NoClassDefFoundError: javax/xml/bind/annotation/XmlRootElement
      at EE.main(EE.java:4)
  Caused by: java.lang.ClassNotFoundException: javax.xml.bind.annotation.XmlRootElement
      at java.base/jdk.internal.loader.BuiltinClassLoader.loadClass(BuiltinClassLoader.java:580)
  exit=1
```

This is the classic "worked fine for years, breaks the moment the JVM changes"
case — nothing about the *application* code changed, only what the runtime bundles.
