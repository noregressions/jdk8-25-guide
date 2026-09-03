# 33 — Distribution changes

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

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | P | P | P | P | P | P | P | P | P | . |

**What the JDK does, release by release:**

**8–16** Applet API present without a removal warning · **17–25** deprecated for removal, so identical source now warns · **26** Applet API removed: the source no longer compiles at all

**Shape:** **window** — arrives, then stops: the API this test needs was removed later, so the difference can no longer be expressed · first differs at **17**, reverts at **26**

Two-stage: the JRE/Web Start changes land at 11 and the Applet API is removed at 26, where this test stops compiling. Also vendor-sensitive — Temurin's JDK 8 never shipped Web Start or JavaFX at all.

<!-- matrix:end -->
