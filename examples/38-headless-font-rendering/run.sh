#!/usr/bin/env bash
# 38 -- Headless font rendering. Not a JDK-version-boundary bug at all -- it
# affects JDK 8 and JDK 25 identically, on any base image that's missing
# fontconfig and a font package. It's included in this suite because it's a
# real, common failure teams hit specifically WHILE migrating (moving to a new
# base image at the same time as the JDK upgrade is a common combined change).
#
# This sandbox has fontconfig and font packages already installed (verified
# below), so AWT text rendering works fine here on both JDKs -- there is no
# JDK-8-vs-25 behavioural difference to show, and no safe way to reproduce a
# "fonts missing" host state without either a real minimal container (no
# Docker daemon available -- see ../NOTES.md) or mutating this sandbox's own
# system font directories, which risks breaking other tools sharing this
# environment. This is a genuine SKIP, not a workaround-and-pass.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

echo "fontconfig presence in this sandbox:"
if command -v fc-list >/dev/null 2>&1; then
  echo "  fc-list found: $(fc-list | wc -l) font(s) registered"
else
  echo "  fc-list NOT found"
fi

"$JDK8_HOME/bin/javac" -d out8 FontTest.java
"$JDK25_HOME/bin/javac" -d out25 FontTest.java 2>/dev/null

echo "JDK 8, headless font rendering (control -- expected to pass, fonts ARE present):"
j8_out="$("$JDK8_HOME/bin/java" -cp out8 FontTest 2>&1)"; j8_exit=$?
echo "$j8_out" | sed 's/^/  /'

echo "JDK 25, headless font rendering (control -- expected to pass, fonts ARE present):"
j25_out="$("$JDK25_HOME/bin/java" -cp out25 FontTest 2>&1)"; j25_exit=$?
echo "$j25_out" | sed 's/^/  /'

rm -rf out8 out25

echo
echo "SKIP: this sandbox has fontconfig and fonts installed, so it cannot demonstrate the actual failure (NullPointerException/InternalError on a minimal image missing both). To reproduce for real, with Docker available:"
echo "  docker run --rm -v \"\$JDK25_HOME:/jdk\" -v \"\$PWD:/t\" eclipse-temurin:25-jre-alpine /jdk/bin/java -cp /t/out25 FontTest"
echo "  # then: apk add fontconfig ttf-dejavu   -- and re-run to see it start working"
exit 2
