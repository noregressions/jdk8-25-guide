# 26 — Underscore as identifier

| | |
|---|---|
| **Category** | Recompilation Surprise |
| **Introduced** | JDK 9 (JEP 213 — `_` reserved as a keyword); JDK 21/22 (JEP 456 — repurposed as the unnamed variable) |
| **Throws** | Compile error: `underscore not allowed here` / `as of release 9, '_' is a keyword` |
| **Detect** | Recompile against the target JDK — the compiler tells you immediately |
| **Fix** | Rename the identifier. |

## What this test does

`Underscore.java` declares `int _ = 42;` — legal in Java 8, a reserved keyword from
Java 9 onward. This demonstrates the *recompilation paradox* directly: the same
`.class` file, once produced, runs identically forever regardless of target JDK. Only
recompiling the *source* against a newer `javac` breaks.

## Note on this pilot's original scope

The reference doc's item #26 also expected item #28 (string concatenation evaluation
order) to be a clean, easily-demonstrated example for this category. It isn't — see
`../NOTES.md` for what actually happened when that one was tested for real. This
pilot swaps in #26 instead, which held up exactly as documented.

## Verified output (2026-08-07, Temurin 8u502 / Temurin 25.0.4)

```
$ javac8 Underscore.java
Underscore.java:3: warning: '_' used as an identifier
        int _ = 42;
            ^
  (use of '_' as an identifier might not be supported in releases after Java SE 8)
2 warnings
COMPILED OK

$ java8 Underscore      # old binary, old JVM
value=42

$ java25 Underscore     # SAME .class file, run on JDK 25 -- still fine
value=42

$ javac25 Underscore.java     # recompile the SAME source with javac 25
Underscore.java:4: error: underscore not allowed here
        System.out.println("value=" + _);
                                      ^
1 error
```

The binary never breaks. Only recompiling the source does — which is exactly why
"old binaries" and "recompiled binaries" need to be tested as two separate failure
sets during a migration, not assumed to behave the same way.
