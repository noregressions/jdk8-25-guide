# 35 — Build toolchain minimums

**Full details:** [Chapter 3.35 — Build Toolchain Minimums](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.35-build-toolchain-minimums.md)

## What this test does — real ASM, one concrete instance of the pattern

`setup-asm.sh` fetches two real ASM jars from Maven Central (7.3.1 and 9.8 — the
reference doc's own stated minimum). Compiles a trivial `Target` class with
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

New ASM (9.8, the reference doc's stated minimum) parsing the SAME class file:
  parsed class: Target
```
