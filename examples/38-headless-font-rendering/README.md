# 38 — Headless font rendering

**Full details:** [Chapter 3.38 — Headless Font Rendering](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.38-headless-font-rendering.md)

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
