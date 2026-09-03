# M01 — Deprecation stages, release by release

## What this test does

M00 asks "was this API present at release N?" — a yes/no. This asks the finer question
the lifecycle diagram is built on: at release N, was the API **supported**, **plainly
deprecated**, **deprecated for removal**, or **gone**?

Both answers come from the JDK's own record rather than from a JEP:

```
javac --release N       -- is it in ct.sym at all?
jdeprscan --release N   -- and if so, what does its @Deprecated say there?
```

28 assertions across nine features. Every one was measured first and then written down;
this test is what stops them drifting.

## The trap: substring matching

`jdeprscan` prints one line per deprecated declaration:

```
@Deprecated(since="1.2", forRemoval=true) void java.lang.Thread.stop(java.lang.Throwable)
@Deprecated(since="1.2")                  void java.lang.Thread.stop()
```

An early version of this probe matched on `java.lang.Thread.stop(` and therefore
reported `Thread.stop()` as terminally deprecated from **JDK 9** — because the
`stop(Throwable)` overload genuinely was, and was removed in 11. The real answer for
`stop()` is JDK 18.

The test now strips the annotation and compares the remaining declaration exactly. If
you add a feature, give it the full declaration including the parameter list.

## A finding: jdeprscan does not report Nashorn's deprecation

Checked on every run, because the Nashorn row of the diagram cannot be built from
`jdeprscan` alone:

```
jdeprscan blind spot at release 11:
  javac -Xlint:deprecation warnings for Nashorn: 1
  jdeprscan --list entries mentioning nashorn:  0
  -> confirmed: the deprecation is in ct.sym, and jdeprscan does not report it
```

JEP 335 deprecated the Nashorn engine in JDK 11. `javac -Xlint:deprecation` warns about
it at `--release 11`, so the annotation is in `ct.sym`. `jdeprscan --release 11 --list`
reports nothing for it — and at `--release 8`, before the module system, it *does* list
`jdk.nashorn` members. The scan set from 9 onward evidently does not include
`jdk.scripting.nashorn`.

The practical consequence is the one Chapter 1.2 is about: a clean `jdeprscan` report is
not evidence that nothing you use is deprecated. It is evidence about the `java.se` API
surface only.

## Running it

```bash
JDK25_HOME=/path/to/jdk25 ./run.sh          # 26 checked, 2 unchecked
JDK25_HOME=/path/to/jdk26 ./run.sh          # all 28 checked
```

`ct.sym` only covers releases up to the running JDK, so the two JDK 26 transitions —
`Thread.stop()` and `java.applet.Applet` being removed — are reported as unchecked
against an earlier target rather than assumed. Both were confirmed on Temurin 26.0.2.
