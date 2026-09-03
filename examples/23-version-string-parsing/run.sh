#!/usr/bin/env bash
# 23 -- Version-string parsing breaks (JEP 223).
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 Ver.java
"$JDK25_HOME/bin/javac" -d out25 Ver.java 2>/dev/null

echo "JDK 8, naive java.version parsing:"
j8_out="$("$JDK8_HOME/bin/java" -cp out8 Ver 2>&1)"
echo "$j8_out" | sed 's/^/  /'

echo "JDK 25, naive java.version parsing (identical code):"
j25_out="$("$JDK25_HOME/bin/java" -cp out25 Ver 2>&1)"
echo "$j25_out" | sed 's/^/  /'

echo "Attempting to compile the modern fix (Runtime.version()) under JDK 8:"
compile8_out="$("$JDK8_HOME/bin/javac" -d out8 VerModern.java 2>&1)"; compile8_exit=$?
echo "$compile8_out" | sed 's/^/  /'
echo "  exit=$compile8_exit"

rm -rf out8 out25

# The naive parser yields the target's own major version, so the expectation is
# derived from the target JDK rather than hardcoded. Hardcoding 25 made this test
# pass only when the target happened to be 25, which the release matrix exposed:
# it looked like the behaviour arrived at 25 when it actually arrived at 9.
target_major=$("$JDK25_HOME/bin/java" -version 2>&1 \
  | sed -n 's/.*version "\([0-9][0-9]*\)\..*/\1/p;s/.*version "1\.\([0-9][0-9]*\).*/\1/p' | head -1)
echo "target major version (derived): $target_major"

ok=true
echo "$j8_out" | grep -q 'startsWith("1.") = true' || ok=false
echo "$j8_out" | grep -q "extraction (split on first dot) = 1$" || ok=false
echo "$j25_out" | grep -q 'startsWith("1.") = false' || ok=false
echo "$j25_out" | grep -q "extraction (split on first dot) = $target_major\$" || ok=false
[ "$compile8_exit" -ne 0 ] || ok=false
echo "$compile8_out" | grep -q "cannot find symbol" || ok=false

if $ok; then
  echo "REPRODUCED: naive java.version parsing correctly (if fragilely) identifies '1' as the major version on JDK 8, and silently gets '$target_major' -- not '1' -- on the target with the exact same code. The correct fix, Runtime.version(), doesn't even exist to fall back on if you're still compiling against JDK 8."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
