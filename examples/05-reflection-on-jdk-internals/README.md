# 05 — Reflection on JDK internals

**Full details:** [Chapter 3.5 — Reflection on JDK Internals](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.05-reflection-on-jdk-internals.md)

## What this test does

`Reflect.java` calls `String.class.getDeclaredField("value").setAccessible(true)` —
exactly the pattern serialisation and DI frameworks (old Spring, Hibernate, Gson) used
routinely to reach a JDK-internal private field. Same source, same class file even —
this is a *runtime* JVM-enforcement difference, not a compile-time one.

## Verified output (2026-08-07, Temurin 8u502 / Temurin 25.0.4)

```
$ java8 Reflect
Access succeeded, field type: class [C
exit=0

$ java25 Reflect
Exception in thread "main" java.lang.reflect.InaccessibleObjectException: Unable to make
field private final byte[] java.lang.String.value accessible: module java.base does not
"opens java.lang" to unnamed module @2b2fa4f7
	at java.base/java.lang.reflect.AccessibleObject.throwInaccessibleObjectException(...)
	...
exit=1
```

Fix it with either of:
```
--add-opens java.base/java.lang=ALL-UNNAMED
```
or upgrade the framework doing the reflecting.
