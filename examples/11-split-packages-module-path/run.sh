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

# --- Would jdeps have warned you? ------------------------------------------------
# Chapter 3.11 used to offer `jdeps -s --module-path ...` as the detector. It is not
# one: jdeps' module summary answers a dependency question, and on a split pair it
# reports both modules resolving cleanly against java.base and exits 0. Pinned here
# so the chapter cannot drift back to recommending it.
echo "jdeps -s --module-path on the same split pair:"
jd_out="$("$JDK25_HOME/bin/jdeps" -s --module-path "outA:outB" --add-modules modA,modB outA 2>&1)"; jd_exit=$?
echo "$jd_out" | sed 's/^/  /'
echo "  exit=$jd_exit"
jd_mentions=$(echo "$jd_out" | grep -ci "in both module\|split package" || true)
echo "  mentions of the split: $jd_mentions"

rm -rf outA outB

if [ "$cp_exit" -eq 0 ] && [ "$mp_exit" -ne 0 ] && echo "$mp_out" | grep -q "LayerInstantiationException"; then
  echo "REPRODUCED: identical split-package setup is silently tolerated on the classpath but a hard LayerInstantiationException on the module path -- and the module path is JDK 9+ only, so this never existed as a failure mode on JDK 8."
  if [ "$jd_exit" -eq 0 ] && [ "$jd_mentions" -eq 0 ]; then
    echo "ALSO REPRODUCED: jdeps does not surface this. Its module summary reports both modules resolving cleanly and exits 0, with no mention of the shared package -- so a clean jdeps run is not evidence that the module path will boot. The trial run above is the detector."
    exit 0
  fi
  echo "UNEXPECTED: jdeps reported something about the split (exit=$jd_exit, mentions=$jd_mentions) -- the chapter may be able to recommend it after all."
  exit 1
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
