#!/usr/bin/env bash
# M01 -- the deprecation *stages* behind the release-lifecycle diagram.
#
# M00 answers "was this API present at release N?", which is a yes/no. This one asks
# the finer question the lifecycle diagram needs: at release N, was the API supported,
# plainly deprecated, deprecated for removal, or gone? Those are four states, and the
# gap between the middle two is where a migration gets its warning.
#
# Both answers come out of the JDK's own record rather than from a JEP:
#   javac --release N     -- is it in ct.sym at all?
#   jdeprscan --release N -- and if so, what does its @Deprecated say there?
#
# Limits. ct.sym only covers releases up to the running JDK, so transitions at 26 are
# checked only when the target is 26 or later, and reported as unchecked otherwise.
# And this is the compile-time API: a method can be present and throw, which is what
# the Part 3 behaviour tests cover.
set -uo pipefail
: "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
JAVAC="$JDK25_HOME/bin/javac"
SCAN="$JDK25_HOME/bin/jdeprscan"
[ -x "$SCAN" ] || { echo "SKIP-REASON: no jdeprscan in the target JDK"; exit 2; }

MAXREL="$("$JDK25_HOME/bin/java" -version 2>&1 \
  | sed -n 's/.*version "\([0-9]*\)\..*/\1/p;s/.*version "1\.\([0-9]*\).*/\1/p' | head -1)"
[ -n "$MAXREL" ] || MAXREL=25

# The jdeprscan roster for one release, with the annotation stripped so a declaration
# can be compared exactly. Substring matching is what made an early version of this
# probe report Thread.stop() as terminally deprecated at JDK 9: the pattern also
# matched the stop(Throwable) overload, which genuinely was. Cached per release --
# jdeprscan is the slow part.
roster() { # <release> <for-removal|all>
  local f="$WORK/roster-$1-$2"
  [ -f "$f" ] || {
    if [ "$2" = for-removal ]; then
      "$SCAN" --release "$1" --list --for-removal 2>/dev/null
    else
      "$SCAN" --release "$1" --list 2>/dev/null
    fi | sed 's/^@Deprecated\(([^)]*)\)\{0,1\} //' > "$f"
  }
  cat "$f"
}

# stage <release> <snippet> <exact declaration> -> supported|deprecated|forremoval|removed
stage() {
  printf 'public class Probe { @SuppressWarnings({"deprecation","removal"}) void m() throws Throwable { %s } }\n' \
    "$2" > "$WORK/Probe.java"
  if ! err="$("$JAVAC" --release "$1" -nowarn -d "$WORK/out" "$WORK/Probe.java" 2>&1)"; then
    case "$err" in
      *"cannot find symbol"*|*"does not exist"*|*"is not visible"*) echo removed; return;;
      *) echo "probe-error"; echo "  javac: $err" >&2; return;;
    esac
  fi
  if roster "$1" for-removal | grep -Fxq "$3"; then echo forremoval
  elif roster "$1" all       | grep -Fxq "$3"; then echo deprecated
  else echo supported; fi
}

# One expectation per line: release|expected stage|snippet|declaration|feature
# Every one of these was measured, not remembered; this file is the assertion that
# they stay true.
EXPECT='
8|deprecated|Thread t=null; t.stop();|void java.lang.Thread.stop()|Thread.stop()
18|forremoval|Thread t=null; t.stop();|void java.lang.Thread.stop()|Thread.stop()
26|removed|Thread t=null; t.stop();|void java.lang.Thread.stop()|Thread.stop()
8|deprecated|Thread t=null; t.suspend();|void java.lang.Thread.suspend()|Thread.suspend()
14|forremoval|Thread t=null; t.suspend();|void java.lang.Thread.suspend()|Thread.suspend()
23|removed|Thread t=null; t.suspend();|void java.lang.Thread.suspend()|Thread.suspend()
8|deprecated|ThreadGroup g=null; g.stop();|void java.lang.ThreadGroup.stop()|ThreadGroup.stop()
16|forremoval|ThreadGroup g=null; g.stop();|void java.lang.ThreadGroup.stop()|ThreadGroup.stop()
23|removed|ThreadGroup g=null; g.stop();|void java.lang.ThreadGroup.stop()|ThreadGroup.stop()
8|supported|Object o=new Object(){ protected void finalize(){} }; o.hashCode();|void java.lang.Object.finalize()|Object.finalize()
9|deprecated|Object o=new Object(){ protected void finalize(){} }; o.hashCode();|void java.lang.Object.finalize()|Object.finalize()
18|forremoval|Object o=new Object(){ protected void finalize(){} }; o.hashCode();|void java.lang.Object.finalize()|Object.finalize()
8|supported|System.setSecurityManager(null);|void java.lang.System.setSecurityManager(java.lang.SecurityManager)|setSecurityManager()
17|forremoval|System.setSecurityManager(null);|void java.lang.System.setSecurityManager(java.lang.SecurityManager)|setSecurityManager()
8|supported|java.applet.Applet a=null; a.hashCode();|class java.applet.Applet|Applet
9|deprecated|java.applet.Applet a=null; a.hashCode();|class java.applet.Applet|Applet
17|forremoval|java.applet.Applet a=null; a.hashCode();|class java.applet.Applet|Applet
26|removed|java.applet.Applet a=null; a.hashCode();|class java.applet.Applet|Applet
8|supported|javax.xml.bind.JAXBContext c=null; c.hashCode();|class javax.xml.bind.JAXBContext|Java EE (javax.xml.bind)
11|removed|javax.xml.bind.JAXBContext c=null; c.hashCode();|class javax.xml.bind.JAXBContext|Java EE (javax.xml.bind)
8|supported|new jdk.nashorn.api.scripting.NashornScriptEngineFactory();|class jdk.nashorn.api.scripting.NashornScriptEngineFactory|Nashorn
15|removed|new jdk.nashorn.api.scripting.NashornScriptEngineFactory();|class jdk.nashorn.api.scripting.NashornScriptEngineFactory|Nashorn
8|supported|java.util.jar.Pack200.newPacker();|class java.util.jar.Pack200|Pack200
11|forremoval|java.util.jar.Pack200.newPacker();|class java.util.jar.Pack200|Pack200
14|removed|java.util.jar.Pack200.newPacker();|class java.util.jar.Pack200|Pack200
8|supported|java.rmi.activation.ActivationID i=null; i.hashCode();|class java.rmi.activation.ActivationID|RMI Activation
15|forremoval|java.rmi.activation.ActivationID i=null; i.hashCode();|class java.rmi.activation.ActivationID|RMI Activation
17|removed|java.rmi.activation.ActivationID i=null; i.hashCode();|class java.rmi.activation.ActivationID|RMI Activation
'

pass=0; fail=0; unchecked=0
printf '%-26s %-4s %-12s %-12s\n' FEATURE REL EXPECTED MEASURED
printf '%s\n' "-------------------------------------------------------------"
while IFS='|' read -r rel want snippet decl feature; do
  [ -n "${rel:-}" ] || continue
  if [ "$rel" -gt "$MAXREL" ]; then
    printf '%-26s %-4s %-12s %s\n' "$feature" "$rel" "$want" "unchecked (target is JDK $MAXREL)"
    unchecked=$((unchecked+1)); continue
  fi
  got="$(stage "$rel" "$snippet" "$decl")"
  if [ "$got" = "$want" ]; then
    printf '%-26s %-4s %-12s %-12s ok\n' "$feature" "$rel" "$want" "$got"
    pass=$((pass+1))
  else
    printf '%-26s %-4s %-12s %-12s MISMATCH\n' "$feature" "$rel" "$want" "$got"
    fail=$((fail+1))
  fi
done <<< "$EXPECT"

echo
echo "$pass matched, $fail mismatched, $unchecked unchecked"

# A finding this test produced, reported every run because it is the reason the Nashorn
# row of the lifecycle diagram cannot be built from jdeprscan alone.
nash_javac=$(printf 'public class N { void m(){ new jdk.nashorn.api.scripting.NashornScriptEngineFactory(); } }\n' \
  > "$WORK/N.java"; "$JAVAC" --release 11 -Xlint:deprecation -d "$WORK/out" "$WORK/N.java" 2>&1 | grep -c deprecat)
nash_scan=$(roster 11 all | grep -c nashorn)
echo
echo "jdeprscan blind spot at release 11:"
echo "  javac -Xlint:deprecation warnings for Nashorn: $nash_javac"
echo "  jdeprscan --list entries mentioning nashorn:  $nash_scan"
if [ "$nash_javac" -gt 0 ] && [ "$nash_scan" -eq 0 ]; then
  echo "  -> confirmed: the deprecation is in ct.sym, and jdeprscan does not report it"
else
  echo "  -> NOT reproduced on this JDK; chapter 1.2's caveat needs rechecking"
  fail=$((fail+1))
fi

[ "$fail" -eq 0 ] || exit 1
exit 0
