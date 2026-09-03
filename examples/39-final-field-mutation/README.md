# 39 — Reflective mutation of a final field

## What this test does

Writes to a `private final int` through `Field.setAccessible(true)` + `setInt` — the
thing serialisation frameworks, dependency-injection containers and mocking libraries
do to rebuild an object without calling its constructor.

Three runs: JDK 8, the target JDK, and the target with
`--illegal-final-field-mutation=deny`. The third leg is skipped rather than failed on
releases before 26, where that flag does not exist.

Against a target earlier than 26 the whole test skips under `run-all.sh` — there is no
warning to detect. Under the release matrix it runs anyway and reports the negative,
because "this release still behaves like JDK 8" is exactly what the matrix is asking.
See the item 39 note in [`../README.md`](../README.md).

## The constant-folding trap this test had to avoid

The test reads the field back **through reflection**, not through an ordinary field
access, and that detail matters. `javac` constant-folds a `private final int`
initialised to a literal, so `box.read()` can still return the *old* value after a
perfectly successful reflective write:

```java
final class Box { private final int value = 1; }
box.read()          // may still return 1 -- folded at compile time
field.getInt(box)   // returns 99
```

Written the obvious way, this test would have reported "no change" on every JDK and
looked like a clean negative result. Worth knowing before auditing a codebase for this
pattern: checking behaviour rather than call sites can conclude everything is fine
while the mutation is happening.

## Verified output (Zulu 8.0.482 / Temurin 26.0.2)

```
JDK 8:
  final field now reads: 99
  exit=0

Target JDK (default settings) — on JDK 26:
  WARNING: Final field value in class FinalMutate$Box has been mutated reflectively
           by class FinalMutate in unnamed module @73d16e93
  WARNING: Use --enable-final-field-mutation=ALL-UNNAMED to avoid a warning
  WARNING: Mutating final fields will be blocked in a future release unless final
           field mutation is enabled
  final field now reads: 99
  exit=0

Target JDK with --illegal-final-field-mutation=deny:
  Exception in thread "main" java.lang.IllegalAccessException: class FinalMutate
  cannot set final field FinalMutate$Box.value, unnamed module is not allowed to
  mutate final fields
      at java.base/java.lang.reflect.Field.preSetFinal(Field.java:1504)
      at java.base/java.lang.reflect.Field.setFinal(Field.java:1447)
  exit=1
```

The middle run is the one that matters: the operation the JDK has announced it will
block completes and returns the mutated value. Nothing there separates an application
that will keep working from one that will not — only the `=deny` run does.

## Two corrections this test produced

**`--enable-final-field-mutation` needs a value.** Oracle's "Significant Changes in
the JDK 26 Release" page lists it as a bare flag; the JVM rejects it that way. The
warning text gives the working form: `--enable-final-field-mutation=ALL-UNNAMED`.

**The exception is `IllegalAccessException`, thrown from `Field.setFinal`** — not from
`setAccessible`. That places it one step further along than chapter 3.5's
`InaccessibleObjectException`: access is granted, the *write* is refused.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | P |

**What the JDK does, release by release:**

**8–25** reflective writes to a final field are silent · **26** JEP 500 warns on every such mutation and states the intent to block it; --illegal-final-field-mutation=deny throws today

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **26**

<!-- matrix:end -->
