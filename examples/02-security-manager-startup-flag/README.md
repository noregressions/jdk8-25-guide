# 02 — Security Manager startup flags

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

## Added check: which values are actually fatal?

"`-Djava.security.manager` is startup-fatal on JDK 24+" is the easy summary, and it is
too broad. The VM's own message is specific — it objects to an option that has
"attempted to **allow or enable**" a Security Manager. That is a statement about the
value, not the property.

```
JDK 25, each value of -Djava.security.manager:
  -Djava.security.manager  (bare)                exit=1  Error occurred during initialization of VM
  -Djava.security.manager=allow                  exit=1  Error occurred during initialization of VM
  -Djava.security.manager=disallow               exit=0  starts
  -Djava.security.manager=default                exit=1  Error occurred during initialization of VM
  -Djava.security.manager=mypkg.CustomSM         exit=1  Error occurred during initialization of VM
  fatal: bare =allow =default =mypkg.CustomSM
  starts: =disallow
```

`=disallow` asks for the JDK 24 default, so it attempts neither to allow nor to
enable, and the VM has no objection.

This matters for a flag audit rather than being a curiosity: a configuration carrying
`=disallow` explicitly — belt-and-braces, or added during an earlier migration step —
is already correct and does not need touching. Every other spelling has to go. Advice
to "remove `-Djava.security.manager`" is right four times out of five and wrong once.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | P | P | P |

**What the JDK does, release by release:**

**8–23** -Djava.security.manager accepted at launch · **24–26** any value but =disallow is a VM-init fatal error

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **24**

<!-- matrix:end -->
