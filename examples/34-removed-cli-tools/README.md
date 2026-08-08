# 34 — Removed CLI tools

| | |
|---|---|
| **Category** | Environment, distribution & build toolchain |
| **Introduced** | ⚠ Version-only, several without individually numbered JEPs: `javah` (JDK 10), `jhat` (JDK 9), `rmic` (JDK 15), `wsimport`/`wsgen`/`schemagen` (JDK 11, alongside Java EE removal), `pack200`/`unpack200` (JDK 14, JEP 367) |
| **Symptom** | Build step invoking the tool fails outright |
| **Detect** | Grep build scripts and CI pipelines for each tool name |
| **Fix** | `javah` → annotation processing / `javac -h`; `rmic` → dynamic stub generation (built into RMI since JDK 8); `wsimport`/`wsgen` → the JAX-WS reference implementation as an external dependency. |

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
