#!/usr/bin/env bash
# 19 -- Default GC changed Parallel -> G1 (JEP 248).
#
# No Java source needed -- this is entirely a VM-flag-level check. -XX:+PrintCommandLineFlags
# with no explicit -XX:+Use*GC flag shows which collector the JVM picked on its own.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"

j8_flags="$("$JDK8_HOME/bin/java" -XX:+PrintCommandLineFlags -version 2>&1)"
j25_flags="$("$JDK25_HOME/bin/java" -XX:+PrintCommandLineFlags -version 2>&1)"

echo "JDK 8 default GC-related flags:"
echo "$j8_flags" | grep -oE '\-XX:[+-]Use[A-Za-z0-9]*GC' | sed 's/^/  /'

echo "JDK 25 default GC-related flags:"
echo "$j25_flags" | grep -oE '\-XX:[+-]Use[A-Za-z0-9]*GC' | sed 's/^/  /'

j8_gc=$(echo "$j8_flags" | grep -oE '\-XX:\+Use[A-Za-z0-9]*GC')
j25_gc=$(echo "$j25_flags" | grep -oE '\-XX:\+Use[A-Za-z0-9]*GC')

if [ "$j8_gc" = "-XX:+UseParallelGC" ] && [ "$j25_gc" = "-XX:+UseG1GC" ]; then
  echo "REPRODUCED: JDK 8 defaults to Parallel GC; JDK 25 defaults to G1 -- same unmodified startup command, different collector, different pause/throughput characteristics with zero configuration change."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate. (JDK8=$j8_gc, JDK25=$j25_gc)"
  exit 1
fi
