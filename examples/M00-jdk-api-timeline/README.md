# M00 — the API timeline behind Part 2's tables

## What this test does

Part 2 is almost entirely release claims — this API arrived in that release, that one
was removed in this one — and a wrong release number is invisible: it reads exactly
like a right one.

`javac --release N` is backed by `ct.sym`, the JDK's own record of the API surface of
every release from 8 upward. So one JDK 25 can answer "was this present at release
N?" for all eighteen values of N without installing eighteen JDKs. This test walks
each claim across 8–25 and reports the boundary it finds.

`M00` covers rows from all four Part 2 chapters; `M01`–`M04` are reserved for tests
specific to chapters 2.1–2.4.

## Limits

- **ct.sym stops at the running JDK.** Anything removed in 26 or later shows as
  "present through 25" here. `Thread.stop` is the live example: removed in JDK 26, so
  this test can only confirm it survives to 25, and the removal itself has to be
  confirmed against the JDK 26 API docs.
- **ct.sym is the compile-time API.** That is the right question for "was it
  removed", but says nothing about behaviour — a method can be present and throw.
  `Thread.stop` was callable but throwing from JDK 20; test `10` covers that half.

## Verified output (Temurin 25.0.1)

```
Removed APIs -- last release present / first release absent:
  ok    java.util.jar.Pack200 (2.2: removed 14)              13|14
  ok    Nashorn engine factory (2.2: removed 15)             14|15
  ok    java.rmi.activation.Activatable (2.2: removed 17)    16|17
  ok    Thread.suspend() (2.4: removed 23)                   22|23
  ok    Thread.resume() (2.4: removed 23)                    22|23
  ok    ThreadGroup.stop() (2.4: removed 23)                 22|23
  ok    ThreadGroup.suspend() (2.4: removed 23)              22|23
  ok    ThreadGroup.resume() (2.4: removed 23)               22|23
  ok    ThreadGroup.allowThreadSuspension() (2.4: rm 21)     20|21

Arrived APIs -- first release present:
  ok    java.lang.Record (2.2: arrives 16)                   16
  ok    java.lang.IO (2.4: arrives 25)                       25

Still present on JDK 25 -- the ThreadGroup methods that did NOT go in 23:
  ok    ThreadGroup.destroy()          still present
  ok    ThreadGroup.isDestroyed()      still present
  ok    ThreadGroup.setDaemon(true)    still present
  ok    ThreadGroup.isDaemon()         still present
```

## The `ThreadGroup` split

This is the finding worth carrying: "the `ThreadGroup` lifecycle methods were removed
in 23" is true of only some of them.

| Method | Fate |
|---|---|
| `stop()`, `suspend()`, `resume()` | removed in **23** — old bytecode gets `NoSuchMethodError` |
| `allowThreadSuspension()` | removed in **21**, a release earlier |
| `destroy()`, `isDestroyed()` | **still present** on 25, deprecated for removal, no-op since 16 |
| `setDaemon()`, `isDaemon()` | **still present** on 25, deprecated for removal, ignored since 16 |

The survivors are the reason chapter 3.21 is a Runs-But-Wrong item rather than a
crash: code calling `destroy()` keeps compiling and keeps running, and simply stops
having any effect. Test `21` exercises both halves of that split at runtime.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | P | P | P | P |

**What the JDK does, release by release:**

**8–22** at least one API in the checked set still present · **23–26** the last of them (ThreadGroup stop/suspend/resume) is gone, so the whole documented timeline holds

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **23**

Passes from 23, when the last of the removals it asserts (ThreadGroup stop/suspend/resume) actually happened. Note this is the test that dominates runtime on emulated columns: it makes ~270 `javac --release N` calls.

<!-- matrix:end -->
