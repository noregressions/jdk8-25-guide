#!/usr/bin/env bash
# 16 -- Security paths silently succeed (JEP 486).
#
# This is the "runs but wrong" sibling of test 08 -- code that defensively
# try/catches the setSecurityManager() failure (a completely reasonable pattern
# for code that must also work on JDK 8, or under a framework that installs its
# own SM) ends up with sm == null on JDK 25, and any "if (sm != null)
# checkPermission()" guard downstream just never fires. The operation the security
# policy was supposed to block proceeds instead, with zero errors or warnings.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 SecCheck.java
"$JDK25_HOME/bin/javac" -d out25 SecCheck.java 2>/dev/null

echo "JDK 8:"
j8_out="$("$JDK8_HOME/bin/java" -cp out8 SecCheck 2>&1)"
echo "$j8_out" | sed 's/^/  /'

echo "JDK 25:"
j25_out="$("$JDK25_HOME/bin/java" -cp out25 SecCheck 2>&1)"
echo "$j25_out" | sed 's/^/  /'

rm -rf out8 out25

if echo "$j8_out" | grep -q "operation BLOCKED" && echo "$j25_out" | grep -q "operation PROCEEDED"; then
  echo "REPRODUCED: the exact same 'deny-everything' security policy blocks the operation on JDK 8, and silently lets it through on JDK 25 -- because the defensive try/catch around setSecurityManager() swallows the new UnsupportedOperationException, leaving getSecurityManager() permanently null."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
