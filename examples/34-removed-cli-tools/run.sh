#!/usr/bin/env bash
# 34 -- Removed CLI tools. Pure filesystem check -- no Java code needed,
# same style as test 32.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"

TOOLS="javah jhat rmic wsimport wsgen schemagen pack200 unpack200"
ok=true
echo "Tool          JDK 8      JDK 25"
echo "----          -----      ------"
for tool in $TOOLS; do
  j8="absent"; [ -x "$JDK8_HOME/bin/$tool" ] && j8="present"
  j25="absent"; [ -x "$JDK25_HOME/bin/$tool" ] && j25="present"
  printf "%-13s %-10s %-10s\n" "$tool" "$j8" "$j25"
  [ "$j8" = "present" ] || ok=false
  [ "$j25" = "absent" ] || ok=false
done

if $ok; then
  echo
  echo "REPRODUCED: all 8 tools present in JDK 8's bin/, all 8 absent from JDK 25's bin/. Any build script or CI pipeline invoking one of these fails outright -- 'command not found', not a Java exception."
  exit 0
else
  echo
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
