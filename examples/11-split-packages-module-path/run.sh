#!/usr/bin/env bash
# 11 -- Split packages on the module path (JEP 261).
#
# The module system itself is a JDK 9+ concept, so there's no JDK 8 side of this
# comparison the way most other tests have one -- on JDK 8 there is no module path
# at all, so two JARs both containing com.example classes just merge silently on
# the classpath (whichever JAR comes first on -cp wins, no error, no warning).
# The real regression is comparing the CLASSPATH (still fully supported, still
# silent) against the MODULE PATH on the SAME JDK 25: put those same two packages
# on the module path and the JVM refuses to even build the boot layer.
set -uo pipefail
: "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf outA outB
mkdir -p outA outB

"$JDK25_HOME/bin/javac" -d outA modA/module-info.java modA/com/example/A.java
"$JDK25_HOME/bin/javac" -d outB modB/module-info.java modB/com/example/B.java

echo "JDK 25, classpath (package split across two JARs, same as JDK 8 behaviour):"
cp_out="$("$JDK25_HOME/bin/java" -cp "outA:outB" -version 2>&1)"; cp_exit=$?
echo "$cp_out" | sed 's/^/  /'
echo "  exit=$cp_exit"

echo "JDK 25, module path (same two packages, same classes):"
mp_out="$("$JDK25_HOME/bin/java" --module-path "outA:outB" --add-modules modA,modB -version 2>&1)"; mp_exit=$?
echo "$mp_out" | sed 's/^/  /'
echo "  exit=$mp_exit"

rm -rf outA outB

if [ "$cp_exit" -eq 0 ] && [ "$mp_exit" -ne 0 ] && echo "$mp_out" | grep -q "LayerInstantiationException"; then
  echo "REPRODUCED: identical split-package setup is silently tolerated on the classpath but a hard LayerInstantiationException on the module path -- and the module path is JDK 9+ only, so this never existed as a failure mode on JDK 8."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
