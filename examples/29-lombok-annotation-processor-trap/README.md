# 29 — The Lombok trap

| | |
|---|---|
| **Category** | Recompilation Surprises |
| **Introduced** | ⚠ JDK 23 — no dedicated JEP; `javac`'s implicit annotation-processor discovery disabled by default (a compiler behaviour change) |
| **Symptom** | Build "succeeds"; Lombok-generated getters/setters/builders are silently absent; `NoSuchMethodError` at runtime |
| **Detect** | Check Lombok version; verify the annotation processor is explicitly configured (`annotationProcessorPaths` in Maven, `annotationProcessor` in Gradle) |
| **Fix** | Lombok **1.18.42+** for JDK 25 class-file support *and* explicit processor configuration — updating the version alone is not sufficient. |

## What this test does — real Lombok, not a simulation

`setup-lombok.sh` fetches two actual Lombok jars from Maven Central (1.18.30 and
1.18.42) — this test doesn't simulate annotation processing, it runs the real
thing. `Person.java` uses `@Getter @Setter`. Two different callers exercise two
different failure shapes:

- `MainDirect.java` calls `p.setName(...)`/`p.getName()` directly — a compile-time
  symbol reference. When the generated methods never materialize, this fails to
  **compile** ("cannot find symbol") — a harder, more visible failure than the
  doc's "build succeeds silently" framing suggests.
- `MainReflective.java` looks up the same methods via `Class.getMethod(...)` —
  no compile-time symbol reference at all. This compiles fine either way, and
  only fails at **runtime**, with `NoSuchMethodException` — this is the scenario
  the doc's Symptom line is actually describing, and it's real, but it's the
  reflective/framework-style caller (a web framework binding request params via
  reflection, a serialization library, etc.), not the everyday direct-call case.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4, real Lombok 1.18.30/1.18.42)

```
1. JDK 8, Lombok 1.18.30, no explicit -processorpath:
  compile exit=0, run exit=0: Ada 30

2. JDK 25, Lombok 1.18.42, no explicit -processorpath, DIRECT method call:
  MainDirect.java:9: error: cannot find symbol
      p.setName("Ada");
       ^
    symbol:   method setName(String)
    location: variable p of type Person
  ...
  compile exit=1

3. JDK 25, Lombok 1.18.42, no explicit -processorpath, REFLECTIVE method call:
  compile exit=0 (this is expected to be 0 -- "the build succeeds")
  Exception in thread "main" java.lang.NoSuchMethodException: Person.setName(java.lang.String)
      at java.base/java.lang.Class.getMethod(Class.java:2166)
      at MainReflective.main(MainReflective.java:5)
  run exit=1

4. JDK 25, Lombok 1.18.42, WITH explicit -processorpath (the fix):
  compile exit=0, run exit=0: Ada 30
```

Note: this test used Lombok 1.18.42 for both the "fails" and "fixed" checks —
the fix that matters here is the explicit `-processorpath`, not the Lombok
version bump. A separate, quick check confirmed the *old* jar (1.18.30) fails
identically without an explicit processor path on JDK 25 — so the version
requirement in the doc's Fix column is about JDK-25-class-file *support*
generally, not specifically about this discovery-disabled behaviour.
