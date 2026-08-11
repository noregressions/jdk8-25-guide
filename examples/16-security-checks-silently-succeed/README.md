# 16 — Security paths silently succeed

**Full details:** [Chapter 3.16 — Security Paths Silently Succeed](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.16-security-checks-silently-succeed.md)

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
