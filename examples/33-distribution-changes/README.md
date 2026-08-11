# 33 — Distribution changes

**Full details:** [Chapter 3.33 — Distribution Changes: JRE, Web Start, JavaFX, Applets](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.33-distribution-changes.md)

## What this test does — and an honest vendor caveat found while building it

Checks for `javaws` (Web Start) and JavaFX in this sandbox's JDK 8 build, and
compiles a small `Applet` subclass under both JDKs with `-Xlint:all`.

**Caveat**: this sandbox uses Eclipse Temurin, which — it turns out — never
bundled Java Web Start or JavaFX even on JDK 8. Both were historically
Oracle/Sun JDK-specific distribution features, not something every vendor's
JDK 8 build included. So there's no true "present on 8, gone on 25" comparison
to run for those two sub-claims with *this* vendor — a team that actually
migrated off Oracle JDK 8 would see the drop; a team that was already on
Temurin, Corretto, or another OpenJDK-based 8 build for other reasons never had
it to lose. This is worth knowing on its own: "distribution changes" can depend
on which JDK 8 you're leaving, not just which JDK 25 you're arriving at.

What **is** vendor-independent and directly verified: the Applet API's
deprecation-for-removal warning is new since JDK 17 (JEP 398) and doesn't fire
on JDK 8's `javac` at all, for identical source.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
Java Web Start (javaws) and JavaFX bundling, this vendor's JDK 8 build:
  javaws: absent (Temurin never bundled this even on JDK 8 -- Oracle-only historically)
  javafx: absent (same caveat)

Applet API deprecation warning, JDK 8:
  Applet.java:5: warning: [serial] serializable class Applet has no definition of serialVersionUID
  1 warning

Applet API deprecation warning, JDK 25 (identical source):
  Applet.java:5: warning: [removal] Applet in java.applet has been deprecated and marked for removal
  Applet.java:5: warning: [serial] serializable class Applet has no definition of serialVersionUID
  2 warnings
```
