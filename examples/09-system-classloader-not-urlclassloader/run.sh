#!/usr/bin/env bash
# 09 -- System classloader is no longer a URLClassLoader (JEP 261).
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 CL.java
echo "JDK 8:"
j8_out="$("$JDK8_HOME/bin/java" -cp out8 CL 2>&1)"; j8_exit=$?
echo "$j8_out" | sed 's/^/  /'
echo "  exit=$j8_exit"

"$JDK25_HOME/bin/javac" -d out25 CL.java
echo "JDK 25:"
j25_out="$("$JDK25_HOME/bin/java" -cp out25 CL 2>&1)"; j25_exit=$?
echo "$j25_out" | sed 's/^/  /'
echo "  exit=$j25_exit"

rm -rf out8 out25

if [ "$j8_exit" -eq 0 ] && echo "$j8_out" | grep -q "cast ok" && \
   [ "$j25_exit" -ne 0 ] && echo "$j25_out" | grep -q "ClassCastException"; then
  echo "REPRODUCED: the system classloader casts cleanly to URLClassLoader on JDK 8; ClassCastException on JDK 25, where it's an internal AppClassLoader that doesn't extend URLClassLoader."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
