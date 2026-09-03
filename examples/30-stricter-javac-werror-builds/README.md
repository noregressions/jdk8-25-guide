# 30 — Stricter `javac` breaks `-Werror` builds

## What this test does

`ThisEscape`'s constructor calls an overridable instance method — `Sub`
overrides that method to read one of its own fields, demonstrating *why* this is
a real risk, not just a lint false-positive: the override can run before `Sub`'s
own state is set up. Compiles the identical two files with `-Xlint:all -Werror`
under both JDKs.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8, -Xlint:all -Werror:
  exit=0

JDK 25, -Xlint:all -Werror (identical source, identical flags):
  ThisEscape.java:9: warning: [this-escape] possible 'this' escape before subclass is fully initialized
          doSomething();
                     ^
  error: warnings found and -Werror specified
  1 error
  1 warning
  exit=1
```

This is the general shape of item 30, not specific to `this-escape` — any of the
dozens of lint categories added across JDK 9-25 can do the same thing to an
`-Werror` build that's never been trial-compiled against the target JDK before
cutting the migration branch.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | . | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–20** javac's lint set has no this-escape category · **21–26** this-escape arrives, so -Xlint:all -Werror fails on unchanged source

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **21**

<!-- matrix:end -->
