#!/usr/bin/env bash
# M00 -- the API timeline behind Part 2's tables, checked against the JDK itself.
#
# Part 2 (chapters 2.1-2.4) is almost entirely release claims: this API arrived in
# that release, that one was removed in this one. Nothing verified them, and a wrong
# release number is invisible -- it reads exactly like a right one.
#
# javac's --release flag is backed by ct.sym, the JDK's own record of the API surface
# of every release from 8 up. So a single JDK 25 can answer "was this present at
# release N?" for every N, without installing eighteen JDKs. This test walks each
# claim across releases 8..25 and reports the boundary it finds.
#
# Limits worth knowing: ct.sym only covers releases up to the running JDK, so
# anything removed in 26+ shows as "present through 25" here and has to be confirmed
# elsewhere (Thread.stop is the current example -- removed in 26, so this test can
# only confirm it survives to 25). ct.sym also records the *compile-time* API, which
# is the right question for "removed" but says nothing about runtime behaviour: a
# method can be present and throw, which is what the Part 3 tests cover.
set -uo pipefail
: "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
JAVAC="$JDK25_HOME/bin/javac"
# ct.sym only knows releases up to the JDK doing the compiling, so the ceiling is
# derived from that JDK rather than hardcoded -- which also lets this test run
# unchanged as a column of the release matrix.
MAXREL="$("$JDK25_HOME/bin/java" -version 2>&1 | sed -n 's/.*version "\([0-9]*\)\..*/\1/p;s/.*version "1\.\([0-9]*\).*/\1/p' | head -1)"
[ -n "$MAXREL" ] || MAXREL=25

# compiles <release> <body> -- does this code compile against that release's API?
compiles() {
  printf 'public class Probe { %s }\n' "$2" > "$WORK/Probe.java"
  "$JAVAC" --release "$1" -nowarn -d "$WORK/out" "$WORK/Probe.java" >/dev/null 2>&1
}

# Walk 8..MAXREL and report the last release that compiled and the first that did not.
boundary() {
  local body="$1" last="" gone=""
  for r in $(seq 8 $MAXREL); do
    if compiles "$r" "$body"; then last="$r"
    elif [ -n "$last" ] && [ -z "$gone" ]; then gone="$r"; fi
  done
  printf '%s|%s' "${last:-none}" "${gone:-none}"
}
first_present() {
  local body="$1" r
  for r in $(seq 8 $MAXREL); do compiles "$r" "$body" && { echo "$r"; return; }; done
  echo none
}

fails=0
pass_or_fail() { # pass_or_fail <label> <expected> <actual>
  if [ "$2" = "$3" ]; then printf '  ok    %-46s %s\n' "$1" "$3"
  else printf '  WRONG %-46s expected %s, got %s\n' "$1" "$2" "$3"; fails=$((fails+1)); fi
}

echo "Removed APIs -- last release present / first release absent:"
check_removed() { # <label> <body> <expected-removal-release>
  local b; b="$(boundary "$2")"
  pass_or_fail "$1" "$(( $3 - 1 ))|$3" "$b"
}
check_removed "java.util.jar.Pack200 (2.2: removed 14)"            "java.util.jar.Pack200 x;"                                  14
check_removed "Nashorn engine factory (2.2: removed 15)"           "jdk.nashorn.api.scripting.NashornScriptEngineFactory x;"   15
check_removed "java.rmi.activation.Activatable (2.2: removed 17)"  "java.rmi.activation.Activatable x;"                        17
check_removed "Thread.suspend() (2.4: removed 23)"                 "void m(Thread t){ t.suspend(); }"                          23
check_removed "Thread.resume() (2.4: removed 23)"                  "void m(Thread t){ t.resume(); }"                           23
check_removed "ThreadGroup.stop() (2.4: removed 23)"               "void m(ThreadGroup g){ g.stop(); }"                        23
check_removed "ThreadGroup.suspend() (2.4: removed 23)"            "void m(ThreadGroup g){ g.suspend(); }"                     23
check_removed "ThreadGroup.resume() (2.4: removed 23)"             "void m(ThreadGroup g){ g.resume(); }"                      23
check_removed "ThreadGroup.allowThreadSuspension() (2.4: rm 21)"   "void m(ThreadGroup g){ g.allowThreadSuspension(true); }"   21
echo "  (ct.sym ceiling for this JDK: release $MAXREL)"

echo ""
echo "Arrived APIs -- first release present:"
check_arrived() { pass_or_fail "$1" "$3" "$(first_present "$2")"; }
check_arrived "java.lang.Record (2.2: arrives 16)"                 "java.lang.Record x;"                                       16
if [ "$MAXREL" -ge 25 ]; then
check_arrived "java.lang.IO (2.4: arrives 25)"                     "java.lang.IO x;"                                           25
fi

echo ""
echo "Still present on JDK $MAXREL -- the ThreadGroup methods that did NOT go in 23:"
for m in "destroy()" "isDestroyed()" "setDaemon(true)" "isDaemon()"; do
  if compiles $MAXREL "void m(ThreadGroup g){ g.$m; }"; then
    printf '  ok    ThreadGroup.%-40s still present\n' "$m"
  else
    printf '  WRONG ThreadGroup.%-40s absent at %s\n' "$m" "$MAXREL"; fails=$((fails+1))
  fi
done

echo ""
if [ "$fails" = "0" ]; then
  echo "REPRODUCED: every release boundary Part 2 claims for these APIs matches the JDK's own ct.sym record. The ThreadGroup split is the one worth restating: stop/suspend/resume were removed at 23 and allowThreadSuspension at 21, but destroy/isDestroyed/setDaemon/isDaemon are all still present at 25 -- so \"the ThreadGroup lifecycle methods were removed\" is only true of some of them, and the survivors are why chapter 3.21 is a Runs-But-Wrong item rather than a crash."
  exit 0
else
  echo "DID NOT REPRODUCE: $fails release boundary/boundaries disagree with Part 2 -- investigate."
  exit 1
fi
