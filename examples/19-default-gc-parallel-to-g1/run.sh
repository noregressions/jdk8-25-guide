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

# The character class needs the digits. Chapter 3.19 once documented this detection
# with [A-Za-z]*GC, which matches UseParallelGC on JDK 8 and silently matches NOTHING
# on JDK 25 -- because the flag it is hunting is UseG1GC, and the "1" falls outside
# the class. An empty result reads as "no GC flag set", which is the wrong conclusion
# from the right command. Pinned so the chapter cannot drift back to it.
naive=$(echo "$j25_flags" | grep -oE '\-XX:\+Use[A-Za-z]*GC' || true)
echo "naive pattern Use[A-Za-z]*GC on JDK 25 matched: '${naive:-<nothing>}'"

j8_gc=$(echo "$j8_flags" | grep -oE '\-XX:\+Use[A-Za-z0-9]*GC')
j25_gc=$(echo "$j25_flags" | grep -oE '\-XX:\+Use[A-Za-z0-9]*GC')

if [ -n "$naive" ]; then
  echo "NOTE: the digitless pattern matched '$naive' on JDK 25 -- if the default collector no longer has a digit in its name, chapter 3.19's caveat about the character class may need revisiting."
fi

if [ "$j8_gc" = "-XX:+UseParallelGC" ] && [ "$j25_gc" = "-XX:+UseG1GC" ]; then
  echo "REPRODUCED: JDK 8 defaults to Parallel GC; JDK 25 defaults to G1 -- same unmodified startup command, different collector, different pause/throughput characteristics with zero configuration change."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate. (JDK8=$j8_gc, JDK25=$j25_gc)"
  exit 1
fi
