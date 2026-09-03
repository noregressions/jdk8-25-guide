# 18 — UTF-8 becomes default charset

## What this test does — and why it's two files, not one

The real migration risk here is **cross-version**, not same-process: a file written
under JDK 8's old platform-default charset (historically windows-1252 on Western
European Windows) gets silently misread once the reader defaults to UTF-8 (JDK 18+).
Writing and reading with the *same* JDK and the *same* unforced default will always
agree with itself — that's not a bug, and a same-process round trip is therefore the
wrong shape of test for it (see `../NOTES.md`).

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

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–26** reader default is UTF-8 on this platform at every release, so a windows-1252 file is misread throughout -- the platform default only became *unconditional* UTF-8 at 18 (JEP 400)

**Shape:** **always** — differs at every release *including JDK 8*, so this row establishes nothing about release timing

**Passes even with the target set to JDK 8**, so it establishes nothing about when JEP 400 landed. It forces the writer to windows-1252 and the reader's default is UTF-8 at every release on this platform. The corruption it demonstrates is real; the timing claim is not tested. A genuine boundary probe would read `file.encoding` under a forced non-UTF-8 locale — see `TODO.md`.

<!-- matrix:end -->
