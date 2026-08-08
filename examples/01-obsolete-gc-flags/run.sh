#!/usr/bin/env bash
# 01 -- Obsolete GC flags: -XX:+UseConcMarkSweepGC works on JDK 8, kills startup on JDK 25.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"

echo "JDK 8:"
out8="$("$JDK8_HOME/bin/java" -XX:+UseConcMarkSweepGC -version 2>&1)"
code8=$?
echo "$out8" | sed 's/^/  /'
echo "  exit=$code8"

echo "JDK 25:"
out25="$("$JDK25_HOME/bin/java" -XX:+UseConcMarkSweepGC -version 2>&1)"
code25=$?
echo "$out25" | sed 's/^/  /'
echo "  exit=$code25"

if [ "$code8" -eq 0 ] && [ "$code25" -ne 0 ] && echo "$out25" | grep -qi "Unrecognized VM option"; then
  echo "REPRODUCED: JDK 8 starts fine, JDK 25 refuses to start with 'Unrecognized VM option'."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
