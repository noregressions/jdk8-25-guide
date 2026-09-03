# 28 — String concatenation: bytecode strategy changed, evaluation order did not

## Why this test exists — closing the loop from the pilot

The pilot (`../NOTES.md`) tried the specific example that circulates in
migration write-ups for this claim — printing a `char[]` via `+` concatenation —
and it didn't reproduce (that example turned out to be a different, unrelated,
version-independent gotcha about `Object.toString()` vs `append(char[])`). This
test tries a second, more direct construction — three objects with
side-effecting `toString()` methods, concatenated together — specifically to
give the evaluation-order claim itself a fair, independent shot before writing it
off. It still doesn't reproduce.

**Why it can't**: the JLS specifies that the operands of a `+` expression are
evaluated strictly left-to-right, and this rule sits above and independent of
whichever bytecode sequence `javac` chooses to actually build the resulting
string. `invokedynamic`-based concatenation still pushes each operand's value
onto the stack in source order before the call site fires — JEP 280 changed *how
the JVM assembles the final string*, not *when each piece is computed*. There is
no compiler-legal way to reorder side effects here without violating the language
specification itself, on any JDK version.

## What this test verifies instead

Concatenates three side-effecting objects, compiled once by `javac8` and once by
`javac25`, run three ways (javac8/JDK8, javac25/JDK25, and javac8-on-JDK25 —
cross-version, unrecompiled). All three produce identical `toString()` call
order. Separately, `javap -c` confirms the two `.class` files really do use
different instruction sequences (`StringBuilder.append` chains vs
`invokedynamic ... makeConcatWithConstants`) — so the underlying JEP 280 change is
real and verifiable; it's just not the claim currently written down.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
javac8-compiled, run on JDK 8:
  toString() call #1 on Loud#1
  toString() call #2 on Loud#2
  toString() call #3 on Loud#3
  result = [L1,L2,L3]

javac25-compiled, run on JDK 25:
  toString() call #1 on Loud#1
  toString() call #2 on Loud#2
  toString() call #3 on Loud#3
  result = [L1,L2,L3]

javac8-compiled (old StringBuilder bytecode), run on the NEWER JVM (JDK 25):
  toString() call #1 on Loud#1
  toString() call #2 on Loud#2
  toString() call #3 on Loud#3
  result = [L1,L2,L3]

Bytecode strategy comparison (javap -c):
  javac8-compiled class uses StringBuilder instructions: 15 occurrence(s)
  javac25-compiled class uses invokedynamic instructions: 2 occurrence(s)
```

## What this item does and doesn't support

What's verified: recompiling changes the emitted bytecode shape for string
concatenation — smaller, `invokedynamic`-based, one call site instead of a
`StringBuilder` chain per expression. A real, `javap`-visible difference, and it
matters to anyone reading disassembled output or working with
bytecode-manipulation tools (test 12's category).

What isn't: the evaluation-order and side-effect framing that circulates alongside
it. Two independent attempts here found no reproducing example, and the JLS gives
no room for one. Treat any future claim of reordering as requiring a runnable
demonstration.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–9** concatenation compiles to StringBuilder chains; on 9 the indy strategy calls toString() right-to-left · **10–26** indy concatenation with left-to-right toString() order -- bytecode shape changed, observable order did not

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **10**

**The matrix contradicted this chapter.** Measured 10, documented JDK 9 — and the reason matters: on JDK 9 this test's own `SideEffect.java` calls `toString()` in *reverse* order (3, 2, 1), while releases 10 through 25 call it in order. The chapter says such reordering "cannot, and does not" happen. It does, at exactly one release, which is why a JDK 8 vs 25 comparison could never see it. Pending confirmation on a second JDK 9 build — see `TODO.md`.

<!-- matrix:end -->
