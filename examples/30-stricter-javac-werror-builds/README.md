# 30 — Stricter `javac` breaks `-Werror` builds

| | |
|---|---|
| **Category** | Recompilation Surprises |
| **Introduced** | Cumulative across 17 releases — no single JEP. Notable individual contributors: `this-escape` warning (JDK 21) |
| **Symptom** | New lint/deprecation/removal warnings accumulate release over release; a build with `-Werror` fails on recompile even when the code is functionally fine |
| **Detect** | Trial-compile against the target JDK; triage the new warnings before deciding what `-Werror` should actually cover |
| **Fix** | Fix or explicitly suppress each new warning category; don't blanket-disable `-Werror`. |
| **Not in the deck.** |

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
