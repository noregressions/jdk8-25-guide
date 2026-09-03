#!/usr/bin/env bash
# 07 -- Nashorn JavaScript engine removed (JEP 372).
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 Nashorn.java
echo "JDK 8:"
j8_out="$("$JDK8_HOME/bin/java" -cp out8 Nashorn 2>&1)"; j8_exit=$?
echo "$j8_out" | sed 's/^/  /'
echo "  exit=$j8_exit"

"$JDK25_HOME/bin/javac" -d out25 Nashorn.java
echo "JDK 25:"
j25_out="$("$JDK25_HOME/bin/java" -cp out25 Nashorn 2>&1)"; j25_exit=$?
echo "$j25_out" | sed 's/^/  /'
echo "  exit=$j25_exit"

rm -rf out8 out25

if echo "$j8_out" | grep -q "NashornScriptEngine" && \
   echo "$j25_out" | grep -q "engine = null" && \
   echo "$j25_out" | grep -q "NullPointerException"; then
  nulls=$(echo "$j25_out" | grep -c "byName(.*) = null" || true)
  [ "$nulls" -eq 3 ] || { echo "MISMATCH: expected all 3 engine names to be null on JDK 25, got $nulls"; }
  echo "REPRODUCED: getEngineByName(\"nashorn\") returns a real engine on JDK 8, but silently returns null on JDK 25 -- the failure surfaces as an NPE on the next line, not a clear 'engine not found.'"
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
