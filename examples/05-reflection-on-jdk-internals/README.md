# 05 — Reflection on JDK internals

| | |
|---|---|
| **Category** | Crashes at Runtime |
| **Introduced** | JDK 16 (JEP 396) strong encapsulation by default; JDK 17 (JEP 403) permanent |
| **Throws** | `InaccessibleObjectException` |
| **Detect** | `jdeps --jdk-internals`; `-Xlog:exceptions=info` (catches instances frameworks swallow) |
| **Fix** | Update the framework past the version doing illegal reflective access, or add a targeted `--add-opens` with a tracking issue and a removal date. |

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
