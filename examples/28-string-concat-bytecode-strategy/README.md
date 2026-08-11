# 28 — String concatenation: bytecode strategy changed, evaluation order did not

**Full details:** [Chapter 3.28 — String Concatenation: the Bytecode Changes, the Behaviour Doesn't](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.28-string-concat-bytecode.md)

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

## Recommendation for the reference doc and the deck

Reword item #28 to claim only what's verified: recompiling changes the emitted
bytecode shape for string concatenation (smaller, `invokedynamic`-based, one call
site instead of a `StringBuilder` chain per expression) — a real, `javap`-visible
difference worth knowing about for anyone reading disassembled output or working
with bytecode-manipulation tools (ties into test 12's category). Drop the
evaluation-order / side-effect framing unless a genuine reproducing example
surfaces; none was found across two independent attempts in this repo.
