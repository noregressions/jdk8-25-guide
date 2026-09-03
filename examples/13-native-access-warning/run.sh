#!/usr/bin/env bash
# 13 -- Native access without --enable-native-access (JEP 454 / JEP 472).
#
# JDK 25-only comparison -- see Native.java header for why there's no JDK 8 side.
set -uo pipefail
: "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
mkdir -p out
"$JDK25_HOME/bin/javac" -d out Native.java

echo "JDK 25, without --enable-native-access:"
without_out="$("$JDK25_HOME/bin/java" -cp out Native 2>&1)"; without_exit=$?
echo "$without_out" | sed 's/^/  /'
echo "  exit=$without_exit"

echo "JDK 25, with --enable-native-access=ALL-UNNAMED:"
with_out="$("$JDK25_HOME/bin/java" --enable-native-access=ALL-UNNAMED -cp out Native 2>&1)"; with_exit=$?
echo "$with_out" | sed 's/^/  /'
echo "  exit=$with_exit"

rm -rf out

if [ "$without_exit" -eq 0 ] && echo "$without_out" | grep -q "WARNING.*restricted method" && \
   [ "$with_exit" -eq 0 ] && ! echo "$with_out" | grep -q "WARNING"; then
  echo "REPRODUCED: native downcalls work either way today, but only warn-free with --enable-native-access. The doc's own symptom line (warning today, hard error on a future release) means CI green today can still mean a future-release outage; this test can't reproduce the future hard-error part since it doesn't exist yet on 25."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
