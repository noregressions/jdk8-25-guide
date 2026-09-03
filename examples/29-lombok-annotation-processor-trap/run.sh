#!/usr/bin/env bash
# 29 -- The Lombok trap: javac's implicit annotation-processor discovery
# disabled by default (JDK 23+, no dedicated JEP).
#
# Uses REAL Lombok jars (fetched by setup-lombok.sh from Maven Central), not a
# simulation. Three checks:
#   1. JDK 8, old Lombok, no explicit -processorpath -- works (implicit
#      discovery was still the default).
#   2. JDK 25, new Lombok, no explicit -processorpath -- FAILS TO COMPILE
#      when the caller directly references the generated methods -- a harder and
#      more visible failure than the usual "build succeeds silently" summary.
#   3. JDK 25, new Lombok, caller uses REFLECTION instead of a direct method
#      reference -- compiles "successfully", fails at RUNTIME with
#      NoSuchMethodException. THIS is the silent-build scenario -- it just isn't
#      the only failure mode, and it needs a reflective caller to happen.
#   4. JDK 25, new Lombok, WITH explicit -processorpath -- works (the fix).
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
./setup-lombok.sh >/dev/null

rm -rf out1 out2 out3 out4
mkdir -p out1 out2 out3 out4

echo "1. JDK 8, Lombok $(echo lombok-old.jar), no explicit -processorpath:"
"$JDK8_HOME/bin/javac" -cp lombok-old.jar -d out1 Person.java MainDirect.java >/tmp/c1.log 2>&1
c1_exit=$?
run1_out="$("$JDK8_HOME/bin/java" -cp "out1:lombok-old.jar" MainDirect 2>&1)"; run1_exit=$?
echo "  compile exit=$c1_exit, run exit=$run1_exit: $run1_out"

echo "2. JDK 25, Lombok new, no explicit -processorpath, DIRECT method call:"
c2_out="$("$JDK25_HOME/bin/javac" -cp lombok-new.jar -d out2 Person.java MainDirect.java 2>&1)"; c2_exit=$?
echo "$c2_out" | sed 's/^/  /'
echo "  compile exit=$c2_exit"

echo "3. JDK 25, Lombok new, no explicit -processorpath, REFLECTIVE method call:"
c3_out="$("$JDK25_HOME/bin/javac" -cp lombok-new.jar -d out3 Person.java MainReflective.java 2>&1)"; c3_exit=$?
echo "  compile exit=$c3_exit (this is expected to be 0 -- 'the build succeeds')"
run3_out="$("$JDK25_HOME/bin/java" -cp "out3:lombok-new.jar" MainReflective 2>&1)"; run3_exit=$?
echo "$run3_out" | sed 's/^/  /'
echo "  run exit=$run3_exit"

echo "4. JDK 25, Lombok new, WITH explicit -processorpath (the fix):"
c4_out="$("$JDK25_HOME/bin/javac" -cp lombok-new.jar -processorpath lombok-new.jar -d out4 Person.java MainDirect.java 2>&1)"; c4_exit=$?
run4_out="$("$JDK25_HOME/bin/java" -cp "out4:lombok-new.jar" MainDirect 2>&1)"; run4_exit=$?
echo "  compile exit=$c4_exit, run exit=$run4_exit: $run4_out"

rm -rf out1 out2 out3 out4

ok=true
[ "$c1_exit" -eq 0 ] && [ "$run1_exit" -eq 0 ] || ok=false
[ "$c2_exit" -ne 0 ] || ok=false
echo "$c2_out" | grep -q "cannot find symbol" || ok=false
[ "$c3_exit" -eq 0 ] || ok=false
[ "$run3_exit" -ne 0 ] || ok=false
echo "$run3_out" | grep -q "NoSuchMethodException" || ok=false
[ "$c4_exit" -eq 0 ] && [ "$run4_exit" -eq 0 ] || ok=false

if $ok; then
  echo "REPRODUCED: implicit annotation-processor discovery works fine on JDK 8. On JDK 25 without an explicit -processorpath, Lombok's generated methods never materialize -- direct references fail to COMPILE, while reflective/framework-style calls compile fine and fail at RUNTIME with NoSuchMethodException. Two distinct failure modes from one cause, and only the second is silent. Explicit -processorpath configuration fixes both."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
