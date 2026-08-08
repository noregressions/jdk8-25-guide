# 32 — JDK layout changed

| | |
|---|---|
| **Category** | Environment, distribution & build toolchain |
| **Introduced** | JDK 9 (JEP 220 — Modular Run-Time Images) |
| **Symptom** | `rt.jar`, `tools.jar`, and the `jre/` directory no longer exist |
| **Detect** | Grep build scripts and code for `rt.jar`, `tools.jar`, `/jre/` |
| **Fix** | Use the `ToolProvider` / `javax.tools` APIs instead of loading `tools.jar` directly; drop any `$JAVA_HOME/jre/...` path assumptions. |

## What this test does

No Java code needed — this is a pure filesystem check, and it's a good representative
of the whole "Environment" category: often the *first* thing that breaks, before any
runtime-behaviour category gets the chance to. Checks for `jre/`, `jre/lib/rt.jar`,
and `lib/tools.jar` under both `$JDK8_HOME` and `$JDK25_HOME`.

## Verified output (2026-08-07, Temurin 8u502 / Temurin 25.0.4)

```
$ ls $JDK8_HOME
ASSEMBLY_EXCEPTION  LICENSE  NOTICE  THIRD_PARTY_README  bin  include  jre  lib  man  release  sample  src.zip
$ ls $JDK8_HOME/jre/lib/rt.jar     -> exists
$ ls $JDK8_HOME/lib/tools.jar      -> exists

$ ls $JDK25_HOME
NOTICE  bin  conf  include  legal  lib  man  release
$ ls $JDK25_HOME/jre                -> No such file or directory
$ ls $JDK25_HOME/lib/rt.jar          -> No such file or directory
$ ls $JDK25_HOME/lib/tools.jar       -> No such file or directory
```

Any build script, agent, or IDE config that assumes `$JAVA_HOME/jre/lib/rt.jar` or
puts `tools.jar` on the classpath fails outright on JDK 25 — not with a Java
exception, just a missing file.
