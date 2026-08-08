# Notes from building the pilot

## Fixed (properly, on the second attempt): #18 (UTF-8 default charset) failed on Steve's Mac

### Attempt 1 — same-process round trip, relying on ambient locale

The first pilot delivery had `18-utf8-default-charset` pass in this sandbox but
**fail when Steve ran it locally** (macOS, JDK 8 = Zulu 8.0.482, JDK 25 = Temurin
25.0.1, both installed via sdkman — not the sandbox's bundled Temurin builds). Root
cause: the test wrote a string and read it back **within the same JDK, same process**,
relying on the *ambient* locale to make JDK 8's platform-default charset non-UTF-8.
This sandbox's ambient locale is POSIX/C, so JDK 8 picked ASCII and the bug showed up
for free. macOS Terminal defaults to a UTF-8 locale, so JDK 8 picked UTF-8 too — same
as JDK 25 — leaving nothing to detect.

### Attempt 2 — force LANG=C on the JDK 8 invocation

First fix: run the JDK 8 side with `LANG=C LC_ALL=C` forced explicitly in `run.sh`,
rather than depending on the ambient shell. Verified working in this sandbox — **but
Steve re-ran it on his Mac (Zulu 8.0.482) and it still failed**: `file.encoding` under
JDK 8 came back `UTF-8` even with the override. Confirmed: this build's platform-
charset detection doesn't take its cue from `LANG`/`LC_ALL` the way Linux's glibc-based
detection does — it's resolving the default some other way (native macOS locale APIs,
most likely), and the POSIX env vars are just ignored for this purpose.

### Attempt 3 (final) — stop relying on locale-detection at all; test the real, cross-version bug

Stepping back: a same-process round trip was never the right test for what JEP 400
actually changed. The real risk in a JDK 8 → 25 migration is **cross-version**: a file
written under JDK 8's old platform default gets silently misread once the *reader*
defaults to UTF-8. Same-JDK round trips will always agree with themselves regardless
of what the default happens to be — that was the design flaw in attempts 1 and 2, not
just an environment-detection problem.

Final design: `Write8.java` writes the file under JDK 8 with `-Dfile.encoding=windows-1252`
**forced explicitly as a JVM flag** (a system-property override, not an environment
variable — this has always worked reliably on JDK 8 regardless of platform or vendor,
unlike `LANG`/`LC_ALL`). `Read25.java` then reads that same file under JDK 25's own,
completely unforced default. Verified passing in this sandbox, and verified to still
pass when the whole `run.sh` invocation is wrapped in a simulated `LANG=en_US.UTF-8`
host environment — proving the result no longer depends on ambient locale at all.

I can't verify this specific fix against Zulu 8.0.482 on macOS from this sandbox, but
the mechanism it now relies on (`-Dfile.encoding` as an explicit JVM flag, not an
environment variable) is standard JDK 8 behaviour predating JEP 400 by over a decade,
and doesn't depend on whichever OS-native mechanism a given vendor's build uses to
*infer* the platform default when no override is given. Re-run `./run-all.sh 18` to
confirm.

## Finding: item #28 (string concatenation evaluation order) doesn't hold up as stated

`complete-jdk8-to-25-reference.md` describes item #28 as: *"if a `toString()`
argument has side effects, evaluation order can differ between the old
`StringBuilder`-chain bytecode and the new `invokedynamic` bytecode — only on
recompiled code."* This traces back to the original slide deck's claim on the same
point, and to a specific example that circulates in migration write-ups: that
concatenating a `char[]` (`"value=" + charArray`) prints differently depending on
which `javac` compiled it.

That specific example was tested directly for this pilot and **did not reproduce**:

```
$ javac8 Concat.java && java8 Concat        -> value=[C@2a139a55
$ (same .class, run on java25)              -> value=[C@2b2fa4f7
$ javac25 Concat.java && java25 Concat      -> value=[C@2b2fa4f7
```

All three print the array's `Object.toString()` form. The reason: `"x" + charArray`
has always resolved to `StringBuilder.append(Object)` at the language level, on every
javac version — `char[]` only gets the "prints its contents" treatment when you call
`StringBuilder.append(char[])` *directly*, which concatenation via `+` never does.
This is a long-standing, version-independent gotcha, not a JDK 8→25 recompilation
difference.

More broadly: **evaluation order of the subexpressions in a `+` chain is mandated by
the JLS** (left-to-right, unconditionally) regardless of which bytecode strategy the
compiler uses to implement the concatenation itself. `invokedynamic`-based
concatenation (JEP 280) changes *how* the JVM builds the resulting string — it does
not, and structurally cannot, change the order in which the source-level operands are
evaluated. I have not found a concrete, reproducible Java program where recompiling
under JEP 280 changes observable side-effect ordering, and I'd want one demonstrated
before repeating the claim on a slide.

**Action taken here:** the pilot's Recompilation Surprise example was swapped from
#28 to #26 (underscore as identifier), which tested exactly as documented. #28's
wording needs a second look — either find and cite a real reproducing example, or
soften the claim to something JEP 280 actually supports (compiled bytecode shape and
size, not observable evaluation order).

**Not yet fixed:** `complete-jdk8-to-25-reference.md` and `WORKSHOP-TODO.md` still
carry the original wording for #28 as of this note. Flagging here rather than
silently editing, since it touches a claim that traces back to the original deck.

## Building the remaining 33 (items 02-17, 19-25, 27-38) — findings summary

All 38 items are now built and verified (`./run-all.sh` → 37 passed, 1 skipped,
0 failed). Same discipline as the pilot: every claim was run against real JDK 8
and JDK 25 before being written into a test's `README.md`. Several turned up
findings worth recording here, in addition to what's already noted in each
test's own README:

- **#3 (obsolete GC logging flags)**: the reference doc lumps
  `-XX:+PrintGCDetails` in with the fatal `PrintGC*` family. Empirically it
  isn't fatal at all — it's a kept, working, deprecated alias (same treatment
  as `-verbose:gc`), while `-XX:+PrintGCTimeStamps` and most of the rest of the
  family genuinely are fatal. The doc's "PrintGCDetails, PrintGCTimeStamps and
  the rest... unrecognised, fatal" sentence needs splitting.
- **#8 / #16 (setSecurityManager / security checks)**: confirmed the doc's
  correction empirically — JDK 25 fails even the JDK-18-23-era
  `-Djava.security.manager=allow` opt-out at VM init, one step earlier than the
  plain `UnsupportedOperationException`. Also built the "runs but wrong"
  sibling case (#16): code that defensively try/catches the setSecurityManager
  failure ends up with a security policy that silently never enforces anything
  on JDK 25, with zero errors logged anywhere.
- **#14 (Unsafe)**: confirmed the doc's existing correction (JDK 24, not 25)
  directly, and found `--sun-misc-unsafe-memory-access=deny` lets you preview
  the *future* hard-failure default today, in CI, without waiting for the
  release that ships it.
- **#21 (ThreadGroup degradation)**: the doc's "stop()/suspend()/resume() throw
  since JDK 20" describes `Thread`'s methods (item 10) accurately but not
  `ThreadGroup`'s. `ThreadGroup.stop()` isn't made to throw — it's removed from
  the class entirely. Old bytecode calling it gets `NoSuchMethodError`, and it
  no longer compiles as a call target at all. Harder failure than the doc's
  wording implies; worth a follow-up correction distinguishing the two classes'
  degradation paths.
- **#22 (finalisation)**: the doc's own Detect column names the flag
  `-Dfinalization=disabled` (a system property). Wrong syntax — verified the
  real flag is `--finalization=disabled` (a launcher option, no `-D`). The
  `-D` form has zero effect; caught this only by actually trying both.
- **#24 (biased locking)**: the doc's Symptom line — "No error, a throughput
  regression" — only holds for code that doesn't explicitly request biased
  locking. Configs carrying the old JDK-8-era `-XX:+UseBiasedLocking` tuning
  flag explicitly (a real, once-common recommendation) get a flat
  `Unrecognized VM option` **Won't Start** failure on JDK 25, not a silent
  regression at all. Worth re-categorizing or at least footnoting.
- **#28 (string concatenation evaluation order)**: this is the one item that
  did **not** survive testing at all, on a second, independent attempt (see the
  entry above from the pilot for the first). Tried side-effecting `toString()`
  calls this time instead of a `char[]`; evaluation order was identical across
  javac8/JDK8, javac25/JDK25, and the cross-version javac8-on-JDK25 run, on
  every attempt. The JLS mandates left-to-right operand evaluation regardless
  of the compiler's bytecode strategy — there's no compiler-legal way to
  reorder side effects here. What genuinely changed (confirmed via `javap`):
  the bytecode *shape* (`StringBuilder` chain → `invokedynamic`), not
  evaluation order. **Recommend rewording item #28 in the reference doc** to
  describe only the bytecode-shape change, and dropping the evaluation-order
  claim until a real reproducing example turns up. Not yet edited into the
  source doc as of this note — flagging here per the same policy as the first
  #28 finding.
- **#29 (Lombok)**: built with real Lombok jars (1.18.30, 1.18.42) from Maven
  Central, not a simulation. Found the doc's "build succeeds silently" framing
  is incomplete: a caller that *directly* references the missing generated
  methods fails to **compile**, not just at runtime — the "succeeds silently,
  fails at runtime" story specifically needs a reflective/framework-style
  caller (built and verified separately as `MainReflective.java`).
- **#31 (nestmate access)**: the doc's "smaller class files" claim didn't hold
  for this test's class — it got *bigger* (853B → 1023B) once compiled with
  nestmates, because the `NestMembers` attribute has its own constant-pool
  overhead. The reliable win is cleaner stack traces and one fewer synthetic
  method, not a guaranteed size reduction. Worth softening that line.
- **#33 (distribution changes)**: found that Eclipse Temurin never bundled
  Java Web Start or JavaFX even on JDK 8 — both were Oracle/Sun-JDK-only
  distribution features historically. Couldn't run the "present on 8, gone on
  25" comparison for those two sub-claims with this vendor; only the Applet API
  deprecation-for-removal warning (JEP 398) is directly, vendor-independently
  testable.
- **#36 (TLS/crypto)**: found this sandbox's JDK 8 (Temurin 8u502, a current
  patch) already disables TLSv1/TLSv1.1 by default — that hardening gets
  backported into ongoing JDK 8 security patches too. "JDK 8 allows weak TLS"
  depends on the patch level, not just the major version. Only the default
  keystore type (JKS → PKCS12) turned out to be a clean, deterministic,
  patch-level-independent comparison.
- **#37 (container memory ergonomics)**: no Docker daemon available, but a
  real cgroup v1 memory limit (created directly, no container runtime needed)
  worked as a substitute. Result: both JDK 8 (8u502) and JDK 25 correctly
  respect the cgroup limit — expected, since the reference doc itself says this
  was backported to 8u191, and 8u502 is well past that. This sandbox therefore
  *cannot* reproduce the actual pre-8u191 broken behaviour the doc's Symptom
  line describes; that needs a genuinely old JDK 8 binary not obtainable
  through the current Adoptium API. Also hit a real bash bug while building
  this one: `$$` inside a bare `(...)` subshell is documented to still refer to
  the *parent* shell's PID, not the subshell's — using it to move a process
  into a cgroup silently moved the whole script's own process in, corrupting
  every later "unconstrained" check in the same run. Fixed with `bash -c` to
  get a genuinely distinct PID. Worth remembering for any future test that
  needs to isolate a subshell's actual PID.
- **#38 (headless font rendering)**: genuine SKIP, not a workaround-and-pass.
  This sandbox has fontconfig and 299 fonts already installed, so there's no
  local way to reproduce a missing-fonts failure without either a real minimal
  container (no Docker daemon) or mutating this sandbox's own system font
  directories (rejected — this environment may be shared with other tools that
  also need working font rendering). `run.sh` runs the rendering code as a
  control (confirms it works when fonts ARE present, identically on both JDKs)
  and prints exact Docker commands to reproduce the real failure elsewhere.

## Sandbox environment notes (useful if these tests move to CI)

- No Docker daemon in this sandbox (the `docker` CLI is present, but `docker info`
  can't reach a daemon socket). Temurin JDK 8 and 25 were fetched directly from
  `api.adoptium.net` as tarballs instead — works fine through the sandbox's proxy,
  no container runtime needed for the 37 items that don't require one. Maven
  Central (`repo1.maven.org`) is also reachable through the same proxy, which is
  how tests 29 and 35 fetch real Lombok and ASM jars.
- cgroup v1 controllers ARE available directly under `/sys/fs/cgroup/` (memory,
  cpu, cpuset, etc.) even with no Docker daemon — test 37 uses this directly to
  apply a real memory limit without needing a container runtime at all. Worth
  knowing if a future test needs to simulate other container-like resource
  constraints (CPU quota, PIDs limit) — the same `/sys/fs/cgroup/<controller>/`
  mechanism should work the same way.
- `JAVA_TOOL_OPTIONS` is set in the ambient shell here (sandbox-specific proxy/trust
  store config) and gets echoed to stderr by every `java` invocation
  ("Picked up JAVA_TOOL_OPTIONS: ..."). `run-all.sh` unsets it before running any
  test so this noise doesn't contaminate stderr comparisons. Worth remembering if
  these tests move to a machine with its own ambient `JAVA_TOOL_OPTIONS`.
- This sandbox's default locale is POSIX/C, which made item #18 (UTF-8 default
  charset) reproducible with zero setup — JDK 8's platform-default charset here is
  plain ASCII, so the £-character corruption shows up without needing to force
  `LANG=C` explicitly. On a dev machine with a UTF-8 locale already set, you may need
  `LANG=C LC_ALL=C ./run.sh` to see the JDK 8 side of that difference.
