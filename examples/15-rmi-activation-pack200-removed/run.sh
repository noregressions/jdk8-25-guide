#!/usr/bin/env bash
# 15 -- RMI Activation (JDK 17, JEP 407) and Pack200 (JDK 14, JEP 367) removed.
# Two independent, long-unmaintained corners of the platform, checked together
# since neither has a direct replacement API -- the fix for both is "remove the
# dependency," not "migrate to X."
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
mkdir -p out
"$JDK8_HOME/bin/javac" -d out RmiAct.java Pack.java

echo "java.rmi.activation.ActivationSystem:"
echo "  JDK 8:"
rmi8_out="$("$JDK8_HOME/bin/java" -cp out RmiAct 2>&1)"; rmi8_exit=$?
echo "$rmi8_out" | sed 's/^/    /'; echo "    exit=$rmi8_exit"
echo "  JDK 25 (same .class, no recompile):"
rmi25_out="$("$JDK25_HOME/bin/java" -cp out RmiAct 2>&1)"; rmi25_exit=$?
echo "$rmi25_out" | sed 's/^/    /'; echo "    exit=$rmi25_exit"

echo "java.util.jar.Pack200:"
echo "  JDK 8:"
pack8_out="$("$JDK8_HOME/bin/java" -cp out Pack 2>&1)"; pack8_exit=$?
echo "$pack8_out" | sed 's/^/    /'; echo "    exit=$pack8_exit"
echo "  JDK 25 (same .class, no recompile):"
pack25_out="$("$JDK25_HOME/bin/java" -cp out Pack 2>&1)"; pack25_exit=$?
echo "$pack25_out" | sed 's/^/    /'; echo "    exit=$pack25_exit"

rm -rf out

ok=true
[ "$rmi8_exit" -eq 0 ] || ok=false
[ "$rmi25_exit" -ne 0 ] || ok=false
echo "$rmi25_out" | grep -q "NoClassDefFoundError" || ok=false
[ "$pack8_exit" -eq 0 ] || ok=false
[ "$pack25_exit" -ne 0 ] || ok=false
echo "$pack25_out" | grep -q "NoClassDefFoundError" || ok=false

if $ok; then
  echo "REPRODUCED: both java.rmi.activation and java.util.jar.Pack200 classes run fine on JDK 8, NoClassDefFoundError on JDK 25 -- the JDK no longer ships either."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
