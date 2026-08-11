# 23 — Version-string parsing breaks

**Full details:** [Chapter 3.23 — Version-String Parsing Breaks](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.23-version-string-parsing.md)

## What this test does

Runs identical naive version-parsing code (`startsWith("1.")`, splitting on the
first dot to get a "major version") against both JDKs, then tries to compile the
correct fix (`Runtime.version()`) under JDK 8 to show it isn't an option there —
`Runtime.version()` is JDK 9+ only.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8, naive java.version parsing:
  java.version = 1.8.0_502
  naive check startsWith("1.") = true
  naive major-version extraction (split on first dot) = 1

JDK 25, naive java.version parsing (identical code):
  java.version = 25.0.4
  naive check startsWith("1.") = false
  naive major-version extraction (split on first dot) = 25

Attempting to compile the modern fix (Runtime.version()) under JDK 8:
  VerModern.java:8: error: cannot find symbol
          System.out.println("Runtime.version() = " + Runtime.version());
                                                             ^
    symbol:   method version()
    location: class Runtime
  exit=1
```

The realistic failure mode: `if (System.getProperty("java.version").startsWith("1."))
{ /* Java 8 code path */ } else { /* Java 9+ path, historically dead code for years */ }`
— on JDK 25 the "else" branch, quite possibly untested for a decade, is what runs.
