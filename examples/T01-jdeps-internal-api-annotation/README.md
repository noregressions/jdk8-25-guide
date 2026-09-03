# T01 — jdeps `--jdk-internals`: the module annotation is the whole finding

## What this test does

Compiles one class under JDK 8 that references three JDK-internal types, chosen so
they land in **different modules**, then both scans it with `jdeps --jdk-internals`
and runs it — unmodified, no flags — under JDK 25.

The point is that "JDK internal API" is not a single category. `jdeps` prints the
owning module for every finding, and that module is what decides whether the call
still works on JDK 25. Two of these three still run fine; the third does not.

## Why the failure mode matters

A `jdeps` finding is a **declared bytecode dependency**, so an encapsulated one
fails at link time with `IllegalAccessError` and is opened with `--add-exports`.
`InaccessibleObjectException` is a different failure: it comes from
`setAccessible()`, needs `--add-opens`, and belongs to the reflective path `jdeps`
cannot see at all. The two are easy to conflate, and conflating them means reaching
for `--add-opens` to clear a finding it has no effect on.

## Verified output (Zulu 8.0.482 / Temurin 25.0.1, macOS arm64)

```
jdeps --jdk-internals (JDK 25) on the javac8-compiled class:
     Probe  -> sun.misc.Unsafe                 JDK internal API (jdk.unsupported)
     Probe  -> sun.reflect.ReflectionFactory   JDK internal API (jdk.unsupported)
     Probe  -> sun.security.x509.X509CertImpl  JDK internal API (java.base)

jdeps module annotations:
  sun.misc.Unsafe                -> jdk.unsupported
  sun.reflect.ReflectionFactory  -> jdk.unsupported
  sun.security.x509.X509CertImpl -> java.base

Same class file, RUN unmodified on JDK 25 with no --add-opens/--add-exports:
  ReflectionFactory: OK (true)
  X509CertImpl: java.lang.IllegalAccessError
```

Two findings sit in `jdk.unsupported` — the JDK's deliberate escape hatch — and
both still work. `sun.misc.Unsafe` warns; `sun.reflect.ReflectionFactory` doesn't
even do that. Only the `java.base` finding is genuinely encapsulated, and it fails
with `IllegalAccessError`.

So the triage rule is: **read the module, not the package name**. A `sun.*` prefix
tells you nothing on its own. `jdk.unsupported` means "still works, plan the exit";
any other module means "fix this or add `--add-exports`".

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8–15** sun.security.x509 reachable, so jdeps has no encapsulated case to report · **16–26** it is encapsulated: jdeps annotates by module and IllegalAccessError follows, while jdk.unsupported entries keep working

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **16**

Boundary at 16 matches JEP 396 — the release where `sun.security.x509.X509CertImpl` became genuinely encapsulated, which is what separates it from the `jdk.unsupported` escape hatches this test contrasts it against.

<!-- matrix:end -->
