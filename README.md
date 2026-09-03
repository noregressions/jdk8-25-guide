# JDK 8 → 25 discovery tests

Forty-five self-contained test cases, each one proving a single behaviour difference
between JDK 8 and JDK 25 by compiling and running the same code under both.

Every case is a directory holding its own Java sources, a `run.sh` that exercises them
under both JDKs, and a `README.md` recording what the test does, the output actually
observed, and how the behaviour moved release by release from 8 to 26.

A test **passes** when it reproduces the documented difference. A failure means the
claim no longer holds on the JDKs at hand — which is the point: these are checks on the
documentation, not on a product.

## Requirements

- **A full JDK 8 and a full JDK 25** — the tests compile as well as run, so a JRE is not
  enough.
- **Bash** (macOS or Linux; the setup scripts also detect Windows via Cygwin/MSYS).
- **`curl`**, for the two tests that vendor real third-party jars (Lombok, ASM) from
  Maven Central rather than simulating them.

## Quick start

```sh
cd examples
./run-all.sh
```

`run-all.sh` finds its own JDKs, in this order:

1. `JDK8_HOME` / `JDK25_HOME` from the environment.
2. Paths recorded in `examples/.jdks/` by `setup/download-jdks.sh`.
3. Whatever `setup/find-jdk.sh` can locate on the machine.

Step 3 means the suite usually runs with no setup at all. If it can't find both JDKs:

```sh
./setup/download-jdks.sh              # prefer local installs, fetch from Adoptium if needed
JDK8_HOME=... JDK25_HOME=... ./run-all.sh
```

Run a subset by number:

```sh
./run-all.sh 05 18      # two Part 3 cases
./run-all.sh T02        # a tools case
./run-all.sh M00        # a migration case
```

Run one case on its own — each `run.sh` is standalone and requires both JDK homes to
be set explicitly:

```sh
cd examples/19-default-gc-parallel-to-g1
JDK8_HOME=... JDK25_HOME=... ./run.sh
```

## Reading the results

`run-all.sh` prints each test's output, then a summary table. Test exit codes:

| Code | Status | Meaning |
|---|---|---|
| 0 | PASS | reproduced the documented difference |
| 2 | SKIP | environment can't support the test; it may print `SKIP-REASON: …`, shown in the summary |
| 124 | TIMEOUT | killed after `TEST_TIMEOUT` seconds (default 120) — counted as a failure |
| other | FAIL | did **not** reproduce the documented difference |

Each test runs in its own process group under a watchdog, so a case that hangs — the
usual symptom of a non-daemon thread outliving `main` — gets killed with its JVMs
rather than stalling the suite.

## Layout

```
examples/
  run-all.sh                     # the harness
  setup/
    download-jdks.sh             # find or fetch JDK 8 + 25 into .jdks/
    find-jdk.sh                  # locate a local JDK of a given major version
  NN-slug/                       # 01–39: behaviour differences
  TNN-slug/                      # JDK tooling behaviour (jdeps, jdeprscan, jnativescan, JFR)
  MNN-slug/                      # API timeline and deprecation-lifecycle checks
```

A test case directory contains:

- `README.md` — what the test does (including, where relevant, what it deliberately
  does *not* try to prove), verified output with the exact JDK builds it came from, and
  a release-by-release matrix of where the difference first appears.
- `run.sh` — the executable check: builds and runs the sources under each JDK as the
  case requires, compares the two, and exits with the status above.
- `*.java` — the sources under test.
- `setup-*.sh` — present only where a test vendors real third-party jars; `run.sh`
  invokes it, so there's no separate step to remember.

## The test cases

### Behaviour differences

| | |
|---|---|
| 01 | Obsolete GC flags |
| 02 | Security Manager startup flags |
| 03 | Obsolete GC logging flags |
| 04 | Extension and endorsed-standards mechanisms removed |
| 05 | Reflection on JDK internals |
| 06 | Removed Java EE packages |
| 07 | Nashorn JavaScript engine removed |
| 08 | `System.setSecurityManager()` throws |
| 09 | System classloader is no longer a `URLClassLoader` |
| 10 | `Thread.stop()` / `suspend()` / `resume()` throw |
| 11 | Split packages on the module path |
| 12 | Old bytecode instrumentation libraries |
| 13 | Native access without `--enable-native-access` |
| 14 | `sun.misc.Unsafe` memory-access methods |
| 15 | RMI Activation and Pack200 removed |
| 16 | Security paths silently succeed |
| 17 | CLDR locale data becomes default |
| 18 | UTF-8 becomes default charset |
| 19 | Default GC changed Parallel → G1 |
| 20 | Compact object headers break cached field offsets |
| 21 | ThreadGroup degradation |
| 22 | Finalisation weakened |
| 23 | Version-string parsing breaks |
| 24 | Biased locking disabled and removed |
| 25 | Serialisation drift |
| 26 | Underscore as identifier |
| 27 | `java.lang.IO` and `java.lang.Record` collisions |
| 28 | String concatenation: bytecode strategy changed, evaluation order did not |
| 29 | The Lombok trap |
| 30 | Stricter `javac` breaks `-Werror` builds |
| 31 | Nestmate access — "the one that helps" |
| 32 | JDK layout changed |
| 33 | Distribution changes |
| 34 | Removed CLI tools |
| 35 | Build toolchain minimums |
| 36 | TLS/crypto posture tightened |
| 37 | Container memory ergonomics changed |
| 38 | Headless font rendering |
| 39 | Reflective mutation of a final field |

### Tooling

| | |
|---|---|
| T01 | jdeps `--jdk-internals`: the module annotation is the whole finding |
| T02 | jdeprscan tells you *what*, never *when* |
| T03 | What jnativescan actually sees, and what it actually misses |
| T06 | JFR throw events: what's on by default, and what the throttle eats |

### Migration

| | |
|---|---|
| M00 | The API timeline behind the migration tables |
| M01 | Deprecation stages, release by release |

## Notes

- `examples/.jdks/` holds machine-local JDK paths and any downloaded JDKs; it is
  git-ignored, as are compile output directories and the vendored jars.
- Verified-output blocks name the exact builds they were captured against (mostly
  Temurin 8u502 / Temurin 25.0.4). Different vendors and patch levels can legitimately
  differ — where that mattered, the test's README says so.
