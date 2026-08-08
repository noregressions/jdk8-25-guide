#!/usr/bin/env bash
# 31 -- Nestmate access, "the one that helps" (JEP 181, JDK 11).
#
# Behaviour is identical either way (that's the point -- "the one that helps").
# What this test checks is the class-file-level mechanism swap: synthetic
# access$000 bridge method (javac8) vs NestHost/NestMembers attributes
# (javac25) -- which is exactly the mechanism that can shift a computed
# serialVersionUID, per test 25's "it's the one that helps, but it can trigger
# the one that doesn't" framing.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 Outer.java
"$JDK25_HOME/bin/javac" -d out25 Outer.java 2>/dev/null

echo "Behaviour, JDK 8:"
"$JDK8_HOME/bin/java" -cp out8 Outer | sed 's/^/  /'
echo "Behaviour, JDK 25:"
"$JDK25_HOME/bin/java" -cp out25 Outer | sed 's/^/  /'

bridge8=$("$JDK25_HOME/bin/javap" -p out8/Outer.class | grep -c 'access\$')
nest8=$("$JDK25_HOME/bin/javap" -v out8/Outer.class | grep -c 'NestMembers\|NestHost')
bridge25=$("$JDK25_HOME/bin/javap" -p out25/Outer.class | grep -c 'access\$')
nest25=$("$JDK25_HOME/bin/javap" -v out25/Outer.class | grep -c 'NestMembers\|NestHost')

size8=$(stat -c%s out8/Outer.class)
size25=$(stat -c%s out25/Outer.class)

echo "javac8-compiled Outer.class:  access\$ bridge methods=$bridge8, NestHost/NestMembers attrs=$nest8, size=${size8}B"
echo "javac25-compiled Outer.class: access\$ bridge methods=$bridge25, NestHost/NestMembers attrs=$nest25, size=${size25}B"

rm -rf out8 out25

if [ "$bridge8" -eq 1 ] && [ "$nest8" -eq 0 ] && [ "$bridge25" -eq 0 ] && [ "$nest25" -ge 1 ]; then
  echo "REPRODUCED: identical behaviour on both JDKs, but the underlying mechanism changed -- javac8 emits a synthetic access\$000 bridge method, javac25 uses NestHost/NestMembers attributes with no bridge method at all. Cleaner stack traces, smaller/different class shape, and (per test 25) the exact kind of implementation-detail change that can shift a class's default serialVersionUID."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
