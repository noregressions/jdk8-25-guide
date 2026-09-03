# 08 — `System.setSecurityManager()`

## What this test does — and its limits

Calls `System.setSecurityManager(new SecurityManager())` directly. JDK 8: works.
JDK 25 default: throws `UnsupportedOperationException` right at the call site (a
runtime exception, distinct from test 02's VM-init-time failure — the app gets as
far as `main()` this time). JDK 25 with the JDK-18-23-era `-Djava.security.manager=allow`
opt-out flag: fails even earlier than the default case, at VM init — same failure
mode as test 02 — confirming that by JDK 25 the opt-out window has fully closed.

**This sandbox only has JDK 8 and JDK 25 installed**, so the middle of the timeline
— that `=allow` genuinely works as an opt-out on, say, JDK 20 — is not verified by
this test, only taken from the JEP 411/486 documentation trail. If you have a JDK 18-23 install handy, worth a quick manual
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

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | P | P | P |

**What the JDK does, release by release:**

**8–23** setSecurityManager() installs a manager (throws by default from 18, =allow re-enables) · **24–26** unconditional: the call throws and =allow is itself fatal at VM init

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **24**

Measured 24 rather than 18, because the test also asserts that `-Djava.security.manager=allow` fails at VM init — which is only true from 24. The exception-by-default boundary is 18, as the chapter says; this row measures the closing of the escape hatch.

<!-- matrix:end -->
