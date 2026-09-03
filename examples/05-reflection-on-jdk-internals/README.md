# 05 — Reflection on JDK internals

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

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–16** setAccessible on JDK internals permitted (warned from 9) · **17–26** deny is permanent and --illegal-access is ignored, so only --add-opens works

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **17**

Measured 17 rather than JEP 396's 16, because a leg added during review asserts that `--illegal-access=permit` is ignored — true from 17 (JEP 403) but not at 16, where the flag still works. The encapsulation boundary itself is 16; this row measures the flag's removal.

<!-- matrix:end -->
