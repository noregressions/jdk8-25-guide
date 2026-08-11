# 09 — System classloader is no longer a `URLClassLoader`

**Full details:** [Chapter 3.9 — The System Classloader Is No Longer a URLClassLoader](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.09-system-classloader-not-urlclassloader.md)

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
