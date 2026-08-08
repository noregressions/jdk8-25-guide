# 16 — Security paths silently succeed

| | |
|---|---|
| **Category** | Runs But Wrong (silent behaviour change) |
| **Introduced** | JDK 24 (JEP 486) |
| **Symptom** | `doPrivileged()` executes with no checks; `getSecurityManager()` always returns `null`; code expecting `SecurityException` to block an operation never sees it |
| **Detect** | Search for `catch (SecurityException`, `doPrivileged()`, `checkPermission()`, `getSecurityManager() != null` guards |
| **Fix** | Replace with OS-level sandboxing, container security policies, or application-level authorisation. This is a manual audit — there's no tool that finds "a security check that used to fire and now doesn't." |

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
