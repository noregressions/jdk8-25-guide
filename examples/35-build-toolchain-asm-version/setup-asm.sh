#!/usr/bin/env bash
# Fetches two real ASM jars from Maven Central: 7.3.1 (predates JDK 25 class
# file support) and 9.8 (the first release with JDK 25 support). Real ASM, not a
# simulation -- same reasoning as test 29's real Lombok jars.
set -uo pipefail
cd "$(dirname "$0")"
OLD_VER="7.3.1"
NEW_VER="9.8"
[ -f "asm-old.jar" ] || curl -sL -o asm-old.jar \
  "https://repo1.maven.org/maven2/org/ow2/asm/asm/${OLD_VER}/asm-${OLD_VER}.jar"
[ -f "asm-new.jar" ] || curl -sL -o asm-new.jar \
  "https://repo1.maven.org/maven2/org/ow2/asm/asm/${NEW_VER}/asm-${NEW_VER}.jar"
ls -la asm-old.jar asm-new.jar
