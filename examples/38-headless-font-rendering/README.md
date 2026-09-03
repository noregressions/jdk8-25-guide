# 38 — Headless font rendering

## Status: SKIP (exit code 2) — and why that's the honest result here

This item isn't a JDK-8-vs-25 behavioural difference at all — it affects both
identically, on any base image missing `fontconfig` and a font package. It's in
this suite because teams hit it specifically *while* migrating, since a JDK
upgrade is often bundled with a base-image change in the same release.

This sandbox has `fontconfig` and 299 registered fonts already installed, so
headless AWT text rendering works fine on both JDK 8 and JDK 25 here — there is
no failure to reproduce locally. Two ways to create the missing-fonts
condition were considered and rejected: pointing `FONTCONFIG_PATH`/
`FONTCONFIG_FILE` at empty locations (tried — the JDK's own bundled font
management doesn't consistently route through those env vars, so it didn't
reproduce the failure), and temporarily moving this sandbox's system font
directories out of the way (rejected — this environment may be shared with
other tools that also depend on working font rendering; mutating system state
non-reversibly for one test isn't worth the risk).

`run.sh` runs the actual rendering code as a control (confirming it works when
fonts ARE present, on both JDKs — matching output, no divergence to report),
prints clear manual reproduction instructions for a real minimal container
image, and exits 2 (this suite's SKIP convention).

## Manual reproduction (needs Docker)

```
docker run --rm -v "$JDK25_HOME:/jdk" -v "$PWD:/t" eclipse-temurin:25-jre-alpine \
  /jdk/bin/java -cp /t/out25 FontTest
# expect: java.lang.InternalError or NullPointerException from the font subsystem

# then, inside the same image:
apk add fontconfig ttf-dejavu
# re-run -- now it renders fine, confirming the fix
```

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4 — control only)

```
fontconfig presence in this sandbox:
  fc-list found: 299 font(s) registered

JDK 8, headless font rendering (control -- expected to pass, fonts ARE present):
  rendered fine, font = java.awt.Font[family=SansSerif,name=SansSerif,style=plain,size=12]

JDK 25, headless font rendering (control -- expected to pass, fonts ARE present):
  rendered fine, font = java.awt.Font[family=SansSerif,name=SansSerif,style=plain,size=12]

exit=2 (SKIP)
```

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| s | s | s | s | s | s | s | s | s | s | s | s | s | s | s | s | s | s | s |

**What the JDK does, release by release:**

**8–26** unchanged across every release: headless AWT needs fontconfig and a font from the OS, and fails identically on 8 and 26 when the base image ships neither

**Shape:** **untestable** — no release could be exercised in this environment

Skipped at every release, by design. Not a JDK difference at all: it needs a base image without fontconfig, and faking that would be worse than saying so.

<!-- matrix:end -->
