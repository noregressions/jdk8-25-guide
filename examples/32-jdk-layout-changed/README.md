# 32 — JDK layout changed

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

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8** rt.jar, tools.jar and jre/ all present · **9–26** modular image: all three gone, conf/ and legal/ appear

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **9**

<!-- matrix:end -->
