# 23 — Version-string parsing breaks

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

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8** java.version starts with '1.', so naive parsers read the major version as 1 · **9–26** the '1.' prefix is gone: the same parsers read 9..26 and take the other branch

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **9**

Boundary at 9 matches JEP 223, after a fix: the test hardcoded `= 25` in an assertion, so it could only pass when the target happened to be 25 — making a JDK 9 change look like a JDK 25 one. It now derives the expected major version from the target JDK.

<!-- matrix:end -->
