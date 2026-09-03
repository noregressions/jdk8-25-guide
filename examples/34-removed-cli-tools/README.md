# 34 — Removed CLI tools

## What this test does

Pure filesystem check, no Java code — checks for the executable presence of
eight historically-removed CLI tools in each JDK's `bin/` directory.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
Tool          JDK 8      JDK 25
----          -----      ------
javah         present    absent
jhat          present    absent
rmic          present    absent
wsimport      present    absent
wsgen         present    absent
schemagen     present    absent
pack200       present    absent
unpack200     present    absent
```

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–14** some of the eight tools still in bin/ (jhat went at 9, javah 10, the WS generators 11, pack200 14) · **15–26** rmic goes too: all eight absent

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **15**

<!-- matrix:end -->
