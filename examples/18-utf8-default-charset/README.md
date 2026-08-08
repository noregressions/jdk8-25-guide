# 18 — UTF-8 becomes default charset

| | |
|---|---|
| **Category** | Runs But Wrong (silent behaviour change) |
| **Introduced** | JDK 18 (JEP 400) |
| **Symptom** | Silent file misinterpretation across a JDK 8 → 25 migration when code doesn't specify a charset — worst for files that already existed on disk before the migration |
| **Detect** | Search for `FileReader`, `FileWriter`, `InputStreamReader`, `OutputStreamWriter` without an explicit charset argument |
| **Fix** | Specify `StandardCharsets.UTF_8` (or whatever charset the data actually is) explicitly on every call site. `-Dfile.encoding=COMPAT` is the temporary bridge, not the fix. |

## What this test does — and why it's two files, not one

The real migration risk here is **cross-version**, not same-process: a file written
under JDK 8's old platform-default charset (historically windows-1252 on Western
European Windows) gets silently misread once the reader defaults to UTF-8 (JDK 18+).
Writing and reading with the *same* JDK and the *same* unforced default will always
agree with itself — that's not a bug, and an earlier version of this test made exactly
that mistake (see `../NOTES.md` for the two iterations it took to get here).

So: `Write8.java` writes `"Price " + (char) 0x00A3 + "100"` (0x00A3 = the £ sign) with
`FileWriter` and **no explicit charset**, run under JDK 8 with
`-Dfile.encoding=windows-1252` forced explicitly — simulating the historically-affected
platform deterministically, regardless of what locale the machine actually running
this test happens to have. `Read25.java` then reads that same file with JDK 25's own,
**unforced** default (always UTF-8, per JEP 400, unconditionally) — no override, that's
the point.

## Verified output (2026-08-07, Temurin 8u502 / Temurin 25.0.4)

```
$ java8 -Dfile.encoding=windows-1252 Write8
writer file.encoding = windows-1252
bytes written (10): 50 72 69 63 65 20 A3 31 30 30      <- £ as a single windows-1252 byte

$ java25 Read25
reader file.encoding = UTF-8
read back: matches original = false
read back char[6] = U+FFFD                              <- the Unicode replacement character
```

JDK 8 didn't throw anything when it wrote the file — that's the defining trait of this
whole category. The corruption only becomes visible once something reads the file back
under JDK 25's new default. Confirmed locale-independent by re-running under a forced
`LANG=en_US.UTF-8` host environment — same result, because the test no longer depends
on the ambient locale at all, only on the explicit `-Dfile.encoding` override on the
write side.
