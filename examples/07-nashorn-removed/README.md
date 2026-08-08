# 07 — Nashorn JavaScript engine removed

| | |
|---|---|
| **Category** | Crashes at Runtime |
| **Introduced** | JDK 15 (JEP 372) |
| **Throws** | `NullPointerException` — *not* the exception you'd expect. `getEngineByName("nashorn")` returns `null`, not a thrown error |
| **Detect** | Search for `getEngineByName("nashorn")` / `getEngineByName("js")` |
| **Fix** | GraalJS as a drop-in replacement dependency; check `ScriptEngine` compatibility-mode config. |

## What this test does

Looks up the `"nashorn"` script engine and evaluates `1+1`. On JDK 8 this returns
a real `NashornScriptEngine` and evaluates fine. On JDK 25 `getEngineByName`
returns `null` (no exception at the lookup site itself), and the `NullPointerException`
only appears one line later, on the `.eval()` call — which is exactly why this one
tends to get misdiagnosed as "something wrong with the script" rather than "the
engine was never there."

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
JDK 8:
  engine = jdk.nashorn.api.scripting.NashornScriptEngine@64bfbc86
  result = 2
  exit=0

JDK 25:
  engine = null
  Exception in thread "main" java.lang.NullPointerException: Cannot invoke
  "javax.script.ScriptEngine.eval(String)" because "<local2>" is null
      at Nashorn.main(Nashorn.java:7)
  exit=1
```
