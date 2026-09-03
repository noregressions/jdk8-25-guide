# 16 — Security paths silently succeed

## What this test does — the "runs but wrong" sibling of test 08

Installs a `SecurityManager` subclass that unconditionally denies every
permission, wrapped in a `try/catch` around the install call (a defensive pattern
real code uses, e.g. for portability across JDK 8 and code that might run under a
framework-installed SM already). On JDK 8, installation succeeds and the deny
policy blocks the operation as designed. On JDK 25, installation throws
`UnsupportedOperationException` (test 08's finding) — but because it's caught, the
program never crashes. It just silently continues with `getSecurityManager() ==
null` forever, and any `if (sm != null)` guard downstream simply never executes.
The operation that was supposed to be blocked goes through, and nothing anywhere
logs an error.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8:
  getSecurityManager() = SecCheck$DenyingSecurityManager@70dea4e
  operation BLOCKED by SecurityException: java.lang.SecurityException: denied: ("java.security.AllPermission" "<all permissions>" "<all actions>")

JDK 25:
  could not install SecurityManager: java.lang.UnsupportedOperationException: Setting a Security Manager is not supported
  getSecurityManager() = null
  operation PROCEEDED (no security check enforced)
```

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–17** a Security Manager installs and enforces, so denials happen · **18–26** disallow is the default: the install fails, defensive catch blocks hide it, and every check silently passes

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **18**

Measured 18, six releases earlier than the JEP 486 date usually quoted. From JDK 18 `disallow` is the default, so the defensive `try/catch` already swallows the failure and enforcement is already gone. Chapter 3.16's `introduced:` was corrected to lead with 18 as a result of this measurement.

<!-- matrix:end -->
