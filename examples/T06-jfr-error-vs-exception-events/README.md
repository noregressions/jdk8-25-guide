# T06 — JFR throw events: what's on by default, and what the throttle eats

## What this test does

Throws an exact, known number of Throwables — 3000 of them, every one caught and
swallowed, exactly like a framework fallback path — and counts how many actually
reach a JFR recording. Three runs: Errors under default settings, Exceptions under
default settings, and Exceptions with the throttle removed.

## The two events, and which one to watch

`jdk.JavaExceptionThrow` is **enabled** by default on JDK 25 — `lib/jfr/default.jfc`
sets `enabled=true` under an `exceptions` selection whose default is `throttled`.
Being enabled is not the same as being complete: it is throttled at 100/s in
`default.jfc` and 300/s in `profile.jfc`, and nothing in the recording tells you
events were dropped.

`jdk.JavaErrorThrow` is a separate, **unthrottled** event covering Errors — and
every Throwable that matters in a JDK 8 → 26 migration is an Error:
`NoClassDefFoundError`, `NoSuchMethodError`, `IllegalAccessError`,
`UnsatisfiedLinkError`.

Errors do also surface in `jdk.JavaExceptionThrow` (they are Throwables, and they
appear there duplicated) — but subject to the same throttle. The test measures all
of it rather than asserting a tidier split than the tool delivers.

## Verified output (Temurin 25.0.1, macOS arm64)

```
default.jfc / profile.jfc settings for the two throw events:
  default.jfc: exceptions selection default="throttled", JavaExceptionThrow throttle 100/s
  profile.jfc: exceptions selection default="throttled", JavaExceptionThrow throttle 300/s

Run A -- 3000 Errors thrown, DEFAULT recording settings:
  threw 3000 error(s), all caught
  jdk.JavaErrorThrow ....... 3000
  jdk.JavaExceptionThrow ... 20

Run B -- 3000 Exceptions thrown, DEFAULT recording settings:
  threw 3000 exception(s), all caught
  jdk.JavaExceptionThrow ... 20

Run C -- same 3000 Exceptions, with exceptions=all (throttle removed):
  threw 3000 exception(s), all caught
  jdk.JavaExceptionThrow ... 3000

summary:
  3000 Errors     -> JavaErrorThrow     3000   (default settings, no flag)
  3000 Exceptions -> JavaExceptionThrow 20     (default settings)
  3000 Exceptions -> JavaExceptionThrow 3000   (exceptions=all)
```

**20 out of 3000.** That is the number worth remembering. A migration run that
throws and swallows `InaccessibleObjectException` on a hot path will show a handful
of events and give every appearance of being a minor, occasional problem.

Two practical consequences:

- Watch **`jdk.JavaErrorThrow`** for migration work. It is on by default, it is not
  throttled, and it covers the Errors that migrations actually produce.
- When exceptions matter too, add `exceptions=all`:
  `-XX:StartFlightRecording=filename=migration.jfr,exceptions=all`. It removes the
  throttle and recovers the full count — at a real cost in recording size, which is
  why it is not the default.

Neither of these needs JDK Mission Control. `jfr summary <file>` gives you the event
counts above straight from the command line, which is what this test uses.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | . | P | P |

**What the JDK does, release by release:**

**8–24** JFR throw-event configuration differs from the shape this test asserts · **25–26** JavaExceptionThrow is enabled but throttled, JavaErrorThrow unthrottled

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **25**

<!-- matrix:end -->
