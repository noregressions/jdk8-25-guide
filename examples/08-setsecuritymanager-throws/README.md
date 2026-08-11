# 08 — `System.setSecurityManager()`

**Full details:** [Chapter 3.8 — System.setSecurityManager() Throws](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.08-setsecuritymanager-throws.md)

## What this test does — and its limits

Calls `System.setSecurityManager(new SecurityManager())` directly. JDK 8: works.
JDK 25 default: throws `UnsupportedOperationException` right at the call site (a
runtime exception, distinct from test 02's VM-init-time failure — the app gets as
far as `main()` this time). JDK 25 with the JDK-18-23-era `-Djava.security.manager=allow`
opt-out flag: fails even earlier than the default case, at VM init — same failure
mode as test 02 — confirming that by JDK 25 the opt-out window has fully closed.

**This sandbox only has JDK 8 and JDK 25 installed**, so the middle of the timeline
in the reference doc's correction — that `=allow` genuinely works as an opt-out on,
say, JDK 20 — is not verified by this test, only asserted per the JEP 411/486
documentation trail. If you have a JDK 18-23 install handy, worth a quick manual
check: `java -Djava.security.manager=allow -cp out SetSM` should print `set ok`
there, and only start failing at the call site (not VM init) on 24+.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8:
  set ok
  exit=0

JDK 25 (default):
  Exception in thread "main" java.lang.UnsupportedOperationException: Setting a Security Manager is not supported
      at java.base/java.lang.System.setSecurityManager(System.java:304)
      at SetSM.main(SetSM.java:3)
  exit=1

JDK 25 with -Djava.security.manager=allow (the JDK 18-23 opt-out flag):
  Error occurred during initialization of VM
  java.lang.Error: A command line option has attempted to allow or enable the Security Manager. Enabling a Security Manager is not supported.
  exit=1
```
