# 06 — Removed Java EE packages

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

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–10** javax.xml.bind and the other Java EE modules ship with the JDK · **11–26** removed: NoClassDefFoundError at class-load time

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **11**

<!-- matrix:end -->
