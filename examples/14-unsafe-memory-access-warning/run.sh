#!/usr/bin/env bash
# 14 -- sun.misc.Unsafe memory-access methods (JEP 471 deprecation, JEP 498 warnings).
#
# Three checks: JDK 8 (silent), JDK 25 default (a one-time runtime warning, still
# works), and JDK 25 with --sun-misc-unsafe-memory-access=deny -- which simulates
# the FUTURE default this JEP is heading toward, turning the warning into a real
# UnsupportedOperationException today, on demand, without waiting for that future
# release to actually ship.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 UnsafeTest.java 2>/dev/null
echo "JDK 8:"
j8_out="$("$JDK8_HOME/bin/java" -cp out8 UnsafeTest 2>&1)"; j8_exit=$?
echo "$j8_out" | sed 's/^/  /'
echo "  exit=$j8_exit"

"$JDK25_HOME/bin/javac" -d out25 UnsafeTest.java 2>/dev/null
echo "JDK 25 (default):"
j25_out="$("$JDK25_HOME/bin/java" -cp out25 UnsafeTest 2>&1)"; j25_exit=$?
echo "$j25_out" | sed 's/^/  /'
echo "  exit=$j25_exit"

echo "JDK 25 with --sun-misc-unsafe-memory-access=deny (simulating the future default):"
j25deny_out="$("$JDK25_HOME/bin/java" --sun-misc-unsafe-memory-access=deny -cp out25 UnsafeTest 2>&1)"; j25deny_exit=$?
echo "$j25deny_out" | sed 's/^/  /'
echo "  exit=$j25deny_exit"

rm -rf out8 out25

ok=true
[ "$j8_exit" -eq 0 ] || ok=false
echo "$j8_out" | grep -q "^h.x via Unsafe = 42" || ok=false
[ "$j25_exit" -eq 0 ] || ok=false
echo "$j25_out" | grep -qi "WARNING.*terminally deprecated" || ok=false
[ "$j25deny_exit" -ne 0 ] || ok=false
echo "$j25deny_out" | grep -q "UnsupportedOperationException" || ok=false

if $ok; then
  echo "REPRODUCED: Unsafe memory access is silent on JDK 8, warns-but-works by default on JDK 25, and --sun-misc-unsafe-memory-access=deny turns that warning into a real UnsupportedOperationException today -- a live preview of the eventual future default."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
