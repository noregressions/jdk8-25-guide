# 35 — Build toolchain minimums

## What this test does — real ASM, one concrete instance of the pattern

`setup-asm.sh` fetches two real ASM jars from Maven Central (7.3.1 and 9.8 — the
first release with JDK 25 support). Compiles a trivial `Target` class with
JDK 25, then parses that real `.class` file with `org.objectweb.asm.ClassReader`
under both ASM versions. ASM itself is what Mockito, JaCoCo, and many
Gradle/Maven plugins use internally to read bytecode — this test exercises the
exact mechanism those tools hit, just directly rather than through a full build.

Same root cause as test 12 (class file major version 69), different symptom
shape: ASM wraps the failure in its own `IllegalArgumentException` with its own
message, not the JVM's `UnsupportedClassVersionError` — worth knowing when
triaging a build failure, since the error text won't obviously point at "JDK
version mismatch" the way the JVM's own error does.

## Verified output (sandbox, Temurin 25.0.4, real ASM 7.3.1 / 9.8)

```
Old ASM (7.3.1) parsing a JDK-25-compiled class file:
  Exception in thread "main" java.lang.IllegalArgumentException: Unsupported class file major version 69
      at org.objectweb.asm.ClassReader.<init>(ClassReader.java:196)
      at ReadClass.main(ReadClass.java:14)

New ASM (9.8, the first release supporting JDK 25) parsing the SAME class file:
  parsed class: Target
```

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | P | P | P | P | P | P | P | P | P | P | . |

**What the JDK does, release by release:**

**8–15** class files old enough for ASM 7 to parse · **16–25** ASM 7 fails and ASM 9.8 succeeds · **26** ASM 9.8 fails too -- the floor moves again for the next target

**Shape:** **window** — arrives, then stops: the API this test needs was removed later, so the difference can no longer be expressed · first differs at **16**, reverts at **26**

Passes from 16 and then **flips back at 26**, which is a finding in its own right: ASM 9.8 — the version chapters 3.12 and 3.35 name as the JDK 25 floor — cannot read JDK 26 class files. The floor moves again for the next target.

<!-- matrix:end -->
