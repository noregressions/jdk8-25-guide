# 26 — Underscore as identifier

## What this test does

`Underscore.java` declares `int _ = 42;` — legal in Java 8, a reserved keyword from
Java 9 onward. This demonstrates the *recompilation paradox* directly: the same
`.class` file, once produced, runs identically forever regardless of target JDK. Only
recompiling the *source* against a newer `javac` breaks.

## Verified output (2026-08-07, Temurin 8u502 / Temurin 25.0.4)

```
$ javac8 Underscore.java
Underscore.java:3: warning: '_' used as an identifier
        int _ = 42;
            ^
  (use of '_' as an identifier might not be supported in releases after Java SE 8)
2 warnings
COMPILED OK

$ java8 Underscore      # old binary, old JVM
value=42

$ java25 Underscore     # SAME .class file, run on JDK 25 -- still fine
value=42

$ javac25 Underscore.java     # recompile the SAME source with javac 25
Underscore.java:4: error: underscore not allowed here
        System.out.println("value=" + _);
                                      ^
1 error
```

The binary never breaks. Only recompiling the source does — which is exactly why
"old binaries" and "recompiled binaries" need to be tested as two separate failure
sets during a migration, not assumed to behave the same way.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8** '_' is a legal identifier (warned in 8) · **9–26** '_' is reserved: existing class files still run, the source no longer compiles

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **9**

<!-- matrix:end -->
