#!/usr/bin/env bash
# Fetches two real Lombok jars from Maven Central: one predating the JDK 25
# class-file-version fix (1.18.30), one that supports it (1.18.42+). Both are
# used in run.sh -- this test
# vendors REAL Lombok, not a simulation, because the annotation-processor
# discovery change is a javac/toolchain behaviour, not something worth faking.
set -uo pipefail
cd "$(dirname "$0")"
OLD_VER="1.18.30"
NEW_VER="1.18.42"
[ -f "lombok-old.jar" ] || curl -sL -o lombok-old.jar \
  "https://repo1.maven.org/maven2/org/projectlombok/lombok/${OLD_VER}/lombok-${OLD_VER}.jar"
[ -f "lombok-new.jar" ] || curl -sL -o lombok-new.jar \
  "https://repo1.maven.org/maven2/org/projectlombok/lombok/${NEW_VER}/lombok-${NEW_VER}.jar"
ls -la lombok-old.jar lombok-new.jar
