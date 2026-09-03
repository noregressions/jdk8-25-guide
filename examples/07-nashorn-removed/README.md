# 07 — Nashorn JavaScript engine removed

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

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–14** Nashorn bundled; getEngineByName returns an engine · **15–26** engine removed; the lookup returns null and the NPE lands one line later

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **15**

<!-- matrix:end -->
