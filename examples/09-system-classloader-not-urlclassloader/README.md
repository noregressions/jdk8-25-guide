# 09 — System classloader is no longer a `URLClassLoader`

| | |
|---|---|
| **Category** | Crashes at Runtime |
| **Introduced** | JDK 9 (JEP 261 — Module System; `AppClassLoader` now extends `BuiltinClassLoader`) |
| **Throws** | `ClassCastException` |
| **Detect** | Search for `(URLClassLoader)` casts on `getSystemClassLoader()` / `getContextClassLoader()` |
| **Fix** | Use the `java.class.path` system property, `ServiceLoader`, or construct an explicit child `URLClassLoader` instead of casting the system one. |
| **Not in the deck.** One of the most common real-world JDK 9+ failures — classpath scanners, plugin loaders, and "add a JAR at runtime" hacks did this cast routinely. |

## What this test does

Gets the system classloader and casts it to `java.net.URLClassLoader`.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8:
  classloader = sun.misc.Launcher$AppClassLoader
  cast ok: sun.misc.Launcher$AppClassLoader@4e0e2f2a
  exit=0

JDK 25:
  classloader = jdk.internal.loader.ClassLoaders$AppClassLoader
  Exception in thread "main" java.lang.ClassCastException: class jdk.internal.loader.ClassLoaders$AppClassLoader cannot be cast to class java.net.URLClassLoader (jdk.internal.loader.ClassLoaders$AppClassLoader and java.net.URLClassLoader are in module java.base of loader 'bootstrap')
  exit=1
```
