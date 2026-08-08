#!/usr/bin/env bash
# 06 -- Removed Java EE packages (JEP 320).
#
# javax.xml.bind (JAXB) was bundled in the JDK 8 runtime. Compile+run on JDK 8,
# then run the SAME class file (no recompile) on JDK 25 -- it's not on the
# classpath anymore because the JDK itself no longer ships it.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -f EE.class
mkdir -p out
"$JDK8_HOME/bin/javac" -d out EE.java

echo "JDK 8:"
j8_out="$("$JDK8_HOME/bin/java" -cp out EE 2>&1)"; j8_exit=$?
echo "$j8_out" | sed 's/^/  /'
echo "  exit=$j8_exit"

echo "JDK 25 (same .class file, no recompile):"
j25_out="$("$JDK25_HOME/bin/java" -cp out EE 2>&1)"; j25_exit=$?
echo "$j25_out" | sed 's/^/  /'
echo "  exit=$j25_exit"

rm -rf out

if [ "$j8_exit" -eq 0 ] && [ "$j25_exit" -ne 0 ] && echo "$j25_out" | grep -q "NoClassDefFoundError"; then
  echo "REPRODUCED: javax.xml.bind classes run fine on JDK 8, but NoClassDefFoundError on JDK 25 -- the JDK no longer ships them."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
