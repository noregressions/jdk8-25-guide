# T02 — jdeprscan tells you *what*, never *when*

## What this test does

Compiles one class using four deprecated APIs spanning both deprecation tiers —
three `@Deprecated(forRemoval=true)` and one ordinary `@Deprecated` — then scans it
three ways: with `--for-removal`, without it, and with `--release 8 --for-removal`.

## Why this shapes the workflow

jdeprscan's entire annotation vocabulary is one string: `(forRemoval=true)`. It
prints no version information of any kind — not the release that deprecated an API,
not the release that changes its behaviour, not the release that removes it.

So it gives you a **list of call sites** and nothing else. Which release deprecated
each one, and which release actually breaks it, is a separate manual lookup — the
job Parts 2 and 3 of this guide do. Two findings that print identically can be a
blocker today and a problem for 2029 respectively.

## Verified output (Temurin 25.0.1, macOS arm64)

```
jdeprscan --for-removal:
  Directory out:
  class Deprecated02 uses deprecated method java/lang/System::setSecurityManager(Ljava/lang/SecurityManager;)V (forRemoval=true)
  class Deprecated02 uses deprecated method java/lang/Thread::stop()V (forRemoval=true)
  class Deprecated02 overrides deprecated method java/lang/Object::finalize()V (forRemoval=true)

jdeprscan (no filter):
  Directory out:
  class Deprecated02 uses deprecated method java/lang/System::setSecurityManager(Ljava/lang/SecurityManager;)V (forRemoval=true)
  class Deprecated02 uses deprecated method java/lang/Thread::stop()V (forRemoval=true)
  class Deprecated02 uses deprecated method java/lang/Runtime::exec(Ljava/lang/String;)Ljava/lang/Process;
  class Deprecated02 overrides deprecated method java/lang/Object::finalize()V (forRemoval=true)

jdeprscan --release 8 --for-removal:
  Usage: jdeprscan [options] {dir|jar|class} ...
  [exit code 1, no diagnostic message -- just a usage dump]

occurrences of 'since' in jdeprscan output ....... 0
findings annotated exactly '(forRemoval=true)' ... 3
Runtime::exec with --for-removal ................. 0
Runtime::exec without --for-removal .............. 1
--release 8 --for-removal exit code .............. 1
```

Three things worth keeping from this run:

- **Zero occurrences of "since"** across both scans. The version context has to come
  from somewhere else.
- **`--for-removal` is what separates the two tiers.** `Runtime.exec(String)` is
  ordinary `@Deprecated`, so it vanishes from the filtered scan and reappears in the
  unfiltered one — note it carries no annotation at all, not even `(deprecated)`.
- **`--for-removal` is refused for `--release 8`** (documented: it cannot be used
  with 6, 7, or 8). The refusal is a bare exit 1 plus a usage dump with *no message
  saying why*, which is easy to misread as a typo in your own command line. In a
  JDK 8 migration, 8 is the obvious release to ask about, so this is worth knowing
  before you hit it.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | P | P | P | P | P | P | P | P | . |

**What the JDK does, release by release:**

**8–17** not all three probe APIs are forRemoval yet, so jdeprscan reports fewer than three · **18–25** all three are forRemoval and jdeprscan reports them -- with no release attached to any · **26** Thread.stop no longer exists to be scanned

**Shape:** **window** — arrives, then stops: the API this test needs was removed later, so the difference can no longer be expressed · first differs at **18**, reverts at **26**

Passes from 18 rather than 9, because the assertion requires all three probe APIs to be `forRemoval` — which is only true from 18. Flips back at 26, where `Thread.stop` no longer exists to be scanned.

<!-- matrix:end -->
