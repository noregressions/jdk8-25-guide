# 04 — Extension and endorsed-standards mechanisms removed

**Full details:** [Chapter 3.4 — Extension and Endorsed-Standards Mechanisms Removed](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.04-ext-endorsed-dirs-removed.md)

## What this test does

Runs `-version` with `-Djava.ext.dirs=/tmp` and `-Djava.endorsed.dirs=/tmp` under
both JDKs. Both flags are accepted (silently tolerated, no-op) on JDK 8. Both refuse
to let the VM start at all on JDK 25, each with an explicit, named error rather than
a generic "unrecognized option."

Note: `-Xbootclasspath/a:<path>` (a related, commonly-confused flag) was checked too
and behaves differently — it's still accepted on JDK 25 (it appends to the boot
class path rather than trying to *replace* endorsed standards), so it's not part of
this same breakage and isn't included in the pass/fail check.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 25 with -Djava.ext.dirs=/tmp -version:
  -Djava.ext.dirs=/tmp is not supported.  Use -classpath instead.
  Error: Could not create the Java Virtual Machine.
  exit=1

JDK 25 with -Djava.endorsed.dirs=/tmp -version:
  -Djava.endorsed.dirs=/tmp is not supported. Endorsed standards and standalone APIs
  in modular form will be supported via the concept of upgradeable modules.
  Error: Could not create the Java Virtual Machine.
  exit=1
```

Both JDK 8 runs succeed normally (exit 0, no warning at all — these flags weren't
even deprecated-with-a-warning on 8, just quietly accepted).
