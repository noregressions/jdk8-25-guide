#!/usr/bin/env bash
# 35 -- Build toolchain minimums (same root cause as test 12, exercised through
# a real ASM-based tool instead of the bare JVM class loader).
#
# There is no JEP for this item -- it's an ecosystem
# compatibility-matrix problem, not a JDK behaviour change. This test picks one
# concrete, real instance of it: ASM (used internally by Mockito, JaCoCo, many
# Gradle/Maven plugins) parsing a JDK-25-compiled class file.
set -uo pipefail
: "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
./setup-asm.sh >/dev/null

rm -rf out old_out new_out target
mkdir -p old_out new_out target

"$JDK25_HOME/bin/javac" -d target Target.java

echo "Old ASM (7.3.1) parsing a JDK-25-compiled class file:"
"$JDK25_HOME/bin/javac" -cp asm-old.jar -d old_out ReadClass.java
old_out_result="$("$JDK25_HOME/bin/java" -cp "old_out:asm-old.jar" ReadClass target/Target.class 2>&1)"
echo "$old_out_result" | sed 's/^/  /'

echo "New ASM (9.8, the first release supporting JDK 25) parsing the SAME class file:"
"$JDK25_HOME/bin/javac" -cp asm-new.jar -d new_out ReadClass.java
new_out_result="$("$JDK25_HOME/bin/java" -cp "new_out:asm-new.jar" ReadClass target/Target.class 2>&1)"
echo "$new_out_result" | sed 's/^/  /'

rm -rf old_out new_out target

ok=true
echo "$old_out_result" | grep -q "Unsupported class file major version" || ok=false
echo "$new_out_result" | grep -q "parsed class: Target" || ok=false

if $ok; then
  echo "REPRODUCED: ASM 7.3.1 throws IllegalArgumentException (Unsupported class file major version 69) parsing a real JDK-25-compiled class; ASM 9.8 parses the identical file fine. Any build-time tool built on old ASM -- Mockito, JaCoCo, custom Gradle plugins -- fails the same way, independent of anything in your own application code."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
