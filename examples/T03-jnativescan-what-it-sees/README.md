# T03 — what jnativescan actually sees, and what it actually misses

## What this test does

Scans two classes that perform the **same** restricted FFM operation by different
routes:

- `Nat.java` — declares a `native` method *and* makes an ordinary compiled FFM
  downcall through `Linker::downcallHandle`.
- `Refl.java` — makes that same downcall reflectively, resolving every type by
  name, so nothing lands in the constant pool.

It also asks `javap` whether `MethodHandles.Lookup` declares the method chapter 1.3
named.

## Where the real boundary is

jnativescan reports two different things, per its own help text: "restricted method
calls and 'native' method declarations". The restricted-call half is the reason it
was added in JDK 24, and it means code that reaches FFM purely at runtime — no
`native` keyword anywhere — is **found**, not missed.

The genuine limit is the *reflective* case, and it is the same static-analysis
boundary `jdeps` runs into in chapter 1.1: resolve the types by name and there is
nothing in the constant pool left to scan.

The `findNative` check is included because that name circulates as an FFM entry
point and does not exist. The real lookups are on `java.lang.foreign.SymbolLookup`.

## Verified output (Temurin 25.0.1, macOS arm64)

```
Does java.lang.invoke.MethodHandles$Lookup declare findNative?
  matches for 'findNative' in MethodHandles.Lookup: 0
  (the real FFM entry points are on java.lang.foreign.SymbolLookup:)
    public abstract java.util.Optional<MemorySegment> find(java.lang.String);
    public default MemorySegment findOrThrow(java.lang.String);
    public static SymbolLookup loaderLookup();
    public static SymbolLookup libraryLookup(java.lang.String, Arena);
    public static SymbolLookup libraryLookup(java.nio.file.Path, Arena);

jnativescan on Nat (declared native method + runtime-only FFM downcall):
  out-nat (ALL-UNNAMED):
    Nat:
      Nat::declaredNative(int)int is a native method declaration
      Nat::viaFfm(String)long references restricted methods:
        java.lang.foreign.Linker::downcallHandle(MemorySegment,FunctionDescriptor,Linker$Option[])MethodHandle

jnativescan on Refl (same FFM downcall, resolved reflectively by name):
    <no restricted methods>

jnativescan --print-native-access on Nat:
  ALL-UNNAMED
```

Both halves of `Nat` are reported, and labelled differently — "is a native method
declaration" versus "references restricted methods". That distinction is the useful
one for triage: the first needs a JNI library present at runtime, the second needs
`--enable-native-access` and nothing else.

`Refl` reports `<no restricted methods>` even though it performs the identical
operation.

One detail for the chapter's worked example: `--print-native-access` prints the bare
value `ALL-UNNAMED`, not a `--enable-native-access: ALL-UNNAMED` line. It is designed
to be substituted straight into a flag, which is why it prints nothing else.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | P | P | P |

**What the JDK does, release by release:**

**8–23** jnativescan does not exist · **24–26** it ships, reporting native declarations and restricted calls separately

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **24**

Boundary at 24 is the tool's own arrival: `jnativescan` ships with JDK 24, so the test cannot pass before it exists. A measurement of the toolchain rather than of the platform.

<!-- matrix:end -->
