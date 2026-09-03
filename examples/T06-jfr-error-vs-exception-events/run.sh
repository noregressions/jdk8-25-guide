#!/usr/bin/env bash
# T06 -- JFR throw events: what's on by default, and what the throttle quietly eats.
#
# Three facts about JDK 25's two throw events, all load-bearing for chapter 1.6:
#
#   1. jdk.JavaExceptionThrow is ENABLED by default -- lib/jfr/default.jfc sets
#      enabled=true under an "exceptions" selection that defaults to "throttled".
#   2. It is THROTTLED: 100/s in default.jfc, 300/s in profile.jfc. Under any real
#      load you silently lose most of what you came to look for, and nothing in
#      the recording says events were dropped.
#   3. jdk.JavaErrorThrow is a separate, UNTHROTTLED event covering Errors -- and
#      every Throwable that matters for a JDK 8->26 migration is an Error:
#      NoClassDefFoundError, NoSuchMethodError, IllegalAccessError,
#      UnsatisfiedLinkError. So that is the event to watch.
#
# Errors do also surface in jdk.JavaExceptionThrow (they are Throwables) --
# duplicated, and subject to the same throttle. The test measures all of it rather
# than asserting a tidier split than the tool delivers.
set -uo pipefail
: "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out *.jfr; mkdir -p out
"$JDK25_HOME/bin/javac" -d out Throwers06.java 2>/dev/null

count_of() {  # count_of <jfr file> <event simple name>
  "$JDK25_HOME/bin/jfr" summary "$1" 2>/dev/null \
    | awk -v e="jdk.$2" '$1==e {print $2; found=1} END {if(!found) print 0}'
}

echo "default.jfc / profile.jfc settings for the two throw events:"
for cfg in default profile; do
  f="$JDK25_HOME/lib/jfr/$cfg.jfc"
  [ -f "$f" ] || continue
  sel=$(grep -o 'selection name="exceptions"[^>]*default="[a-z]*"' "$f" | grep -o 'default="[a-z]*"' | head -1)
  thr=$(grep -A3 'name="jdk.JavaExceptionThrow"' "$f" | grep -o '>[0-9]*/s<' | tr -d '></s')
  echo "  $cfg.jfc: exceptions selection $sel, JavaExceptionThrow throttle ${thr}/s"
done

echo ""
echo "Run A -- 3000 Errors thrown, DEFAULT recording settings:"
"$JDK25_HOME/bin/java" -XX:StartFlightRecording=filename=errors.jfr,dumponexit=true \
  -cp out Throwers06 3000 error 2>&1 | grep -v "jfr,startup" | sed 's/^/  /'
a_err=$(count_of errors.jfr JavaErrorThrow)
a_exc=$(count_of errors.jfr JavaExceptionThrow)
echo "  jdk.JavaErrorThrow ....... $a_err"
echo "  jdk.JavaExceptionThrow ... $a_exc"

echo ""
echo "Run B -- 3000 Exceptions thrown, DEFAULT recording settings:"
"$JDK25_HOME/bin/java" -XX:StartFlightRecording=filename=exc.jfr,dumponexit=true \
  -cp out Throwers06 3000 exception 2>&1 | grep -v "jfr,startup" | sed 's/^/  /'
b_exc=$(count_of exc.jfr JavaExceptionThrow)
echo "  jdk.JavaExceptionThrow ... $b_exc"

echo ""
echo "Run C -- same 3000 Exceptions, with exceptions=all (throttle removed):"
"$JDK25_HOME/bin/java" -XX:StartFlightRecording=filename=exc-all.jfr,dumponexit=true,exceptions=all \
  -cp out Throwers06 3000 exception 2>&1 | grep -v "jfr,startup" | sed 's/^/  /'
c_exc=$(count_of exc-all.jfr JavaExceptionThrow)
echo "  jdk.JavaExceptionThrow ... $c_exc"

rm -rf out errors.jfr exc.jfr exc-all.jfr

echo ""
echo "summary:"
echo "  3000 Errors     -> JavaErrorThrow     $a_err   (default settings, no flag)"
echo "  3000 Exceptions -> JavaExceptionThrow $b_exc     (default settings)"
echo "  3000 Exceptions -> JavaExceptionThrow $c_exc   (exceptions=all)"

ok=1
[ "$a_err" -ge 3000 ]  || { echo "MISMATCH: JavaErrorThrow captured $a_err of 3000 -- expected all of them"; ok=0; }
[ "$b_exc" -lt 500 ]   || { echo "MISMATCH: JavaExceptionThrow captured $b_exc by default -- expected heavy throttling"; ok=0; }
[ "$c_exc" -ge 3000 ]  || { echo "MISMATCH: exceptions=all captured $c_exc of 3000 -- expected all of them"; ok=0; }
[ "$a_exc" -gt 0 ]     || { echo "MISMATCH: expected Errors to also surface in JavaExceptionThrow"; ok=0; }

echo ""
if [ "$ok" = "1" ]; then
  echo "REPRODUCED: jdk.JavaExceptionThrow is enabled by default on JDK 25 but throttled, and captured $b_exc of 3000 thrown exceptions with no warning that anything was dropped. jdk.JavaErrorThrow is unthrottled and captured all $a_err Errors under the same default settings. Since every migration-relevant Throwable (NoClassDefFoundError, NoSuchMethodError, IllegalAccessError) is an Error, JavaErrorThrow is the event to watch; where exceptions matter too, exceptions=all removes the throttle and recovers the full $c_exc."
  exit 0
else
  echo "DID NOT REPRODUCE the documented behaviour -- investigate."
  exit 1
fi
