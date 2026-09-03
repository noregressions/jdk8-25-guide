#!/usr/bin/env bash
# 30 -- Stricter javac breaks -Werror builds (cumulative across 17 releases;
# this-escape specifically is JDK 21+).
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

echo "JDK 8, -Xlint:all -Werror:"
j8_out="$("$JDK8_HOME/bin/javac" -Xlint:all -Werror -d out8 ThisEscape.java Sub.java 2>&1)"; j8_exit=$?
echo "$j8_out" | sed 's/^/  /'
echo "  exit=$j8_exit"

echo "JDK 25, -Xlint:all -Werror (identical source, identical flags):"
j25_out="$("$JDK25_HOME/bin/javac" -Xlint:all -Werror -d out25 ThisEscape.java Sub.java 2>&1)"; j25_exit=$?
echo "$j25_out" | sed 's/^/  /'
echo "  exit=$j25_exit"

rm -rf out8 out25

if [ "$j8_exit" -eq 0 ] && [ "$j25_exit" -ne 0 ] && \
   echo "$j25_out" | grep -q "this-escape" && \
   echo "$j25_out" | grep -q "warnings found and -Werror specified"; then
  echo "REPRODUCED: identical source, identical -Xlint:all -Werror flags -- compiles clean on JDK 8, fails the build on JDK 25 because the this-escape lint category (JDK 21+) didn't exist to fire on JDK 8 at all."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
