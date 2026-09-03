#!/usr/bin/env bash
# 25 -- Serialisation drift (no single JEP; side effect of internal implementation
# changes -- including the nestmate change, test 31 -- altering the computed
# serialVersionUID for classes with no EXPLICIT serialVersionUID declared).
#
# Payload.java is compiled ONCE per side: javac8+Write.java for the write side,
# javac25+Read.java for the read side. Same source, same logical class, different
# compiler -- which is exactly the "recompiled" scenario this whole category (Part 4)
# is about, and exactly why the fix (declare serialVersionUID explicitly) works:
# an explicit constant doesn't drift no matter which javac computed it.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 Payload.java Write.java
"$JDK25_HOME/bin/javac" -d out25 Payload.java Read.java 2>/dev/null

echo "Synthetic methods on Payload\$Nested, javac8-compiled:"
"$JDK25_HOME/bin/javap" -p "out8/Payload\$Nested.class" | grep -c "access\\\$" | sed 's/^/  count: /'
echo "Synthetic methods on Payload\$Nested, javac25-compiled:"
"$JDK25_HOME/bin/javap" -p "out25/Payload\$Nested.class" | grep -c "access\\\$" | sed 's/^/  count: /'

echo "Write with JDK 8 (Payload\$Nested compiled by javac8):"
(cd out8 && "$JDK8_HOME/bin/java" -cp . Write) | sed 's/^/  /'
cp out8/obj.ser out25/obj.ser

echo "Read with JDK 25 (Payload\$Nested RECOMPILED by javac25):"
read_out="$(cd out25 && "$JDK25_HOME/bin/java" -cp . Read 2>&1)"
echo "$read_out" | sed 's/^/  /'

rm -rf out8 out25

if echo "$read_out" | grep -q "InvalidClassException" && echo "$read_out" | grep -q "serialVersionUID"; then
  echo "REPRODUCED: recompiling Payload\$Nested under JDK 25 (nestmates, no synthetic accessor) changes its DEFAULT computed serialVersionUID versus the JDK 8 compile (which had one) -- an object serialized on one side can't be deserialized on the other, InvalidClassException, even though nothing about the class's own declared members changed."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
