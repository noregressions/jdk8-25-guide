# 02 — Security Manager startup flags

| | |
|---|---|
| **Category** | Won't Start |
| **Introduced** | Unconditional since JDK 24 (JEP 486). Note: JDK 18-23 already throw at the *call site* if code invokes `System.setSecurityManager()` without `-Djava.security.manager=allow` — see test 08 — but the *startup flag* itself (`-Djava.security.manager` on the command line, no value or `=allow`/`=disallow`/a classname) is only VM-init-fatal from 24 onward. |
| **Throws** | `Error occurred during initialization of VM` — the JVM exits before `main()` runs |
| **Detect** | Audit startup scripts and Docker entrypoints for `-Djava.security.manager` |
| **Fix** | Remove the flag entirely. There is no replacement — the Security Manager is gone. |

## What this test does

Runs `-version` under both JDKs with `-Djava.security.manager` on the command line.
JDK 8 starts normally (the flag just opts in to the standard, unremarkable Security
Manager). JDK 25 refuses to start the VM at all.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8 with -Djava.security.manager -version:
  openjdk version "1.8.0_502"
  ...
  exit=0

JDK 25 with -Djava.security.manager -version:
  Error occurred during initialization of VM
  java.lang.Error: A command line option has attempted to allow or enable the
  Security Manager. Enabling a Security Manager is not supported.
  	at java.lang.System.initPhase3(java.base@25.0.4/System.java:1970)
  exit=1
```

Note this is a *harder* failure than test 08 (`System.setSecurityManager()` called
from code): here the JVM never even reaches `main()`, so there's no stack trace in
application logs to grep for -- the failure is visible only in the process's own
stderr/exit code, which is exactly why it's worth auditing startup scripts directly
rather than waiting for it to show up in an APM tool.
