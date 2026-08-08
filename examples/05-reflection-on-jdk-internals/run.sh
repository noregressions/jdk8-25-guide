#!/usr/bin/env bash
# 05 -- Reflection on JDK internals: setAccessible(true) on a JDK-internal field.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"

mkdir -p /tmp/reflect8 /tmp/reflect25

echo "JDK 8:"
"$JDK8_HOME/bin/javac" -d /tmp/reflect8 Reflect.java
out8="$("$JDK8_HOME/bin/java" -cp /tmp/reflect8 Reflect 2>&1)"; code8=$?
echo "$out8" | sed 's/^/  /'
echo "  exit=$code8"

echo "JDK 25:"
"$JDK25_HOME/bin/javac" -d /tmp/reflect25 Reflect.java
out25="$("$JDK25_HOME/bin/java" -cp /tmp/reflect25 Reflect 2>&1)"; code25=$?
echo "$out25" | sed 's/^/  /'
echo "  exit=$code25"

rm -rf /tmp/reflect8 /tmp/reflect25

if [ "$code8" -eq 0 ] && [ "$code25" -ne 0 ] && echo "$out25" | grep -q "InaccessibleObjectException"; then
  echo "REPRODUCED: JDK 8 allows the reflective access; JDK 25 throws InaccessibleObjectException."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
