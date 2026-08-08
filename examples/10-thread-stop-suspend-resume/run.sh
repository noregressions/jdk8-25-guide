#!/usr/bin/env bash
# 10 -- Thread.stop() / suspend() / resume() throw (JDK 20, no dedicated JEP).
#
# Distinct from the ThreadGroup-level siblings (test 21) -- this is the Thread
# class itself, a separate API surface the deck doesn't mention at all.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 StopTest.java 2>/dev/null
echo "JDK 8:"
j8_out="$("$JDK8_HOME/bin/java" -cp out8 StopTest 2>&1)"; j8_exit=$?
echo "$j8_out" | sed 's/^/  /'
echo "  exit=$j8_exit"

"$JDK25_HOME/bin/javac" -d out25 StopTest.java 2>/dev/null
echo "JDK 25:"
j25_out="$("$JDK25_HOME/bin/java" -cp out25 StopTest 2>&1)"; j25_exit=$?
echo "$j25_out" | sed 's/^/  /'
echo "  exit=$j25_exit"

rm -rf out8 out25

if [ "$j8_exit" -eq 0 ] && echo "$j8_out" | grep -q "returned normally" && \
   [ "$j25_exit" -ne 0 ] && echo "$j25_out" | grep -q "UnsupportedOperationException"; then
  echo "REPRODUCED: Thread.stop() works (if unsafely) on JDK 8; throws UnsupportedOperationException outright on JDK 25."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
