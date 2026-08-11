# 34 — Removed CLI tools

**Full details:** [Chapter 3.34 — Removed CLI Tools](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.34-removed-cli-tools.md)

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
