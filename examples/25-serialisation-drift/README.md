# 25 — Serialisation drift

**Full details:** [Chapter 3.25 — Serialisation Drift](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.25-serialisation-drift.md)

## What this test does

`Payload.Nested` is `Serializable`, has a private field, and doesn't declare an
explicit `serialVersionUID` — so the JVM computes a default one from the class's
own visible + synthetic members. `Nested`'s private field is read from the
enclosing `Payload` class, which pre-nestmates required a synthetic bridge method
(`access$000`) on `Nested` itself; that synthetic method's signature feeds into
the computed UID. Compile with `javac8` (bridge present), serialize an instance,
then try to deserialize that exact byte stream against the identical source
recompiled with `javac25` (bridge gone, nestmates handles the access directly) —
the computed UID differs, and deserialization fails outright.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
Synthetic methods on Payload$Nested, javac8-compiled:
  count: 1
Synthetic methods on Payload$Nested, javac25-compiled:
  count: 0
Write with JDK 8 (Payload$Nested compiled by javac8):
  wrote obj.ser
Read with JDK 25 (Payload$Nested RECOMPILED by javac25):
  Exception in thread "main" java.io.InvalidClassException: Payload$Nested; local class incompatible: stream classdesc serialVersionUID = 9055674887718378473, local class serialVersionUID = -1260671151154697526
```

The practical shape of this bug: an app serializes objects to a database/cache/queue
under JDK 8, then a routine recompile-on-JDK-25 (no source change at all) makes
every previously-stored object unreadable, because the class in question never
declared its own `serialVersionUID` and quietly depended on the compiler to pick
a stable one — which it doesn't, across this exact boundary.
