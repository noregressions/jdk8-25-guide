# 04 — Extension and endorsed-standards mechanisms removed

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

## Added check: the two `Xbootclasspath` suffixes went opposite ways

A grep for `ext.dirs` and `endorsed.dirs` finds `Xbootclasspath` in the same files,
and the two suffixes do not share a fate:

```
JDK 25 with -Xbootclasspath/a:/tmp (append -- expected to survive):
  openjdk version "25.0.1" 2025-10-21 LTS
  exit=0

JDK 25 with -Xbootclasspath/p:/tmp (prepend -- expected to fail):
  -Xbootclasspath/p is no longer a supported option.
  exit=1
```

`/a:` (append to the boot class path) is still supported on JDK 25. `/p:` (prepend)
is rejected — and note it gets its own message rather than the generic
`Unrecognized VM option`, because the launcher still knows the flag and refuses it
specifically.

The practical consequence: an audit hit on `Xbootclasspath` needs reading, not
deleting on sight. Chapter 3.4 previously asserted this control run without the test
actually performing it; it does now.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8** java.ext.dirs and java.endorsed.dirs honoured · **9–26** both rejected by name at launch; -Xbootclasspath/p also gone, /a survives

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **9**

<!-- matrix:end -->
