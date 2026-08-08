# Discovery Tests: JDK 8 → 25, behaviour compared for real

Every item in `docs/complete-jdk8-to-25-reference.md` gets a test case here, numbered
to match that document (`01-...` through `38-...`). Each one runs against **real**
Temurin JDK 8 and JDK 25 builds, side by side, and reports whether the documented
behaviour difference actually reproduces. This isn't a set of assertions taken on
faith from the deck or the guide — it's meant to catch the next factual error before
it ends up on a slide.

## Status: complete (38 of 38 built; 37 pass, 1 clean skip)

| # | Test | Category | Status |
|---|---|---|---|
| 01 | Obsolete GC flags | Won't Start | ✅ verified |
| 02 | Security Manager startup flag | Won't Start | ✅ verified |
| 03 | Obsolete GC logging flags | Won't Start | ✅ verified (+ finding) |
| 04 | Extension/endorsed dirs removed | Won't Start | ✅ verified |
| 05 | Reflection on JDK internals | Crashes at Runtime | ✅ verified |
| 06 | Removed Java EE packages | Crashes at Runtime | ✅ verified |
| 07 | Nashorn removed | Crashes at Runtime | ✅ verified |
| 08 | setSecurityManager() throws | Crashes at Runtime | ✅ verified |
| 09 | System classloader not a URLClassLoader | Crashes at Runtime | ✅ verified |
| 10 | Thread.stop/suspend/resume throw | Crashes at Runtime | ✅ verified |
| 11 | Split packages on module path | Crashes at Runtime | ✅ verified |
| 12 | Old bytecode instrumentation (class file version) | Crashes at Runtime | ✅ verified |
| 13 | Native access warning | Crashes at Runtime | ✅ verified |
| 14 | Unsafe memory access warning | Crashes at Runtime | ✅ verified |
| 15 | RMI Activation / Pack200 removed | Crashes at Runtime | ✅ verified |
| 16 | Security checks silently succeed | Runs But Wrong | ✅ verified |
| 17 | CLDR locale data default | Runs But Wrong | ✅ verified |
| 18 | UTF-8 becomes default charset | Runs But Wrong | ✅ verified |
| 19 | Default GC Parallel → G1 | Runs But Wrong | ✅ verified |
| 20 | Compact object headers default | Runs But Wrong | ✅ verified |
| 21 | ThreadGroup degradation | Runs But Wrong | ✅ verified (+ finding) |
| 22 | Finalisation weakened | Runs But Wrong | ✅ verified (+ finding) |
| 23 | Version-string parsing | Runs But Wrong | ✅ verified |
| 24 | Biased locking removed | Runs But Wrong | ✅ verified (+ finding) |
| 25 | Serialisation drift | Recompilation Surprise | ✅ verified |
| 26 | Underscore as identifier | Recompilation Surprise | ✅ verified |
| 27 | java.lang.IO / Record collision | Recompilation Surprise | ✅ verified |
| 28 | String concat bytecode strategy | Recompilation Surprise | ⚠️ verified, but the doc's claim needed correcting — see NOTES.md |
| 29 | Lombok annotation-processor trap | Recompilation Surprise | ✅ verified (real Lombok) |
| 30 | Stricter javac breaks -Werror | Recompilation Surprise | ✅ verified |
| 31 | Nestmate access | Recompilation Surprise | ✅ verified (+ finding) |
| 32 | JDK layout changed | Environment & toolchain | ✅ verified |
| 33 | Distribution changes | Environment & toolchain | ✅ verified (+ vendor caveat) |
| 34 | Removed CLI tools | Environment & toolchain | ✅ verified |
| 35 | Build toolchain minimums (ASM) | Environment & toolchain | ✅ verified (real ASM) |
| 36 | TLS/crypto posture tightened | Environment & toolchain | ✅ verified (+ finding) |
| 37 | Container memory ergonomics | Environment & toolchain | ✅ verified (+ finding, no Docker needed — real cgroup) |
| 38 | Headless font rendering | Environment & toolchain | ⏭️ SKIP — needs a real minimal container image |

See `NOTES.md` for the full list of findings this build turned up — several items
needed their wording corrected or narrowed once actually tested, which is exactly
what this whole exercise is for.

## Quick start

```bash
./setup/download-jdks.sh     # once -- fetches Temurin 8 + 25 into .jdks/ (gitignored)
./run-all.sh                 # run every test case
./run-all.sh 01 18           # run only specific test numbers
```

Two tests (`29`, `35`) fetch real third-party jars (Lombok, ASM) from Maven Central
on first run via their own `setup-*.sh` — also gitignored.

## How each test case is structured

```
NN-slug/
  README.md   -- Category / Introduced (JEP) / Symptom / Detect / Fix, plus verified output
  run.sh       -- the actual comparison; exit 0 = reproduced, 1 = did NOT reproduce, 2 = skipped
  *.java       -- source, where the test needs one
```

`run-all.sh` sets `JDK8_HOME` / `JDK25_HOME` and calls each `run.sh` in turn. The
harness shape genuinely differs by category — this is deliberate, not an
inconsistency:

- **Won't Start / most Crashes at Runtime** — run an identical artifact under both
  JDK homes, compare exit code and stderr.
- **Recompilation Surprises** — compile the *same source* separately with each JDK's
  `javac`, then run both binaries (and cross-run the old binary on the new JVM) —
  three data points, not two.
- **Environment & toolchain** — often no Java code at all; a filesystem, flag, or
  version-string comparison between the two JDK installations. A couple use a real
  cgroup v1 memory limit directly (no Docker needed) to test container-ergonomics
  behaviour.
- **A few items can't be faithfully automated in this sandbox** — no Docker daemon
  here (the CLI is present but no daemon socket), so anything that genuinely needs a
  minimal/stripped container image (item 38) gets a `run.sh` that exits 2 (skipped)
  with real, copy-pasteable instructions for running it locally with Docker, rather
  than a faked pass.

## Why this exists

`docs/complete-jdk8-to-25-reference.md` already fact-checked several things the deck
and guide got wrong. This folder is the next layer of rigour: instead of trusting a
written claim (mine or the deck's), run it. See `NOTES.md` for the running list of
what that caught across all 38 items — including one item (28) where the documented
claim didn't survive contact with a real JVM at all, and several others where the
claim was directionally right but needed narrowing or correcting once tested.
