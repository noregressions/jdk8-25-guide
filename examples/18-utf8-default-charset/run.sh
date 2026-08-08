#!/usr/bin/env bash
# 18 -- UTF-8 becomes default charset (JEP 400).
#
# The real migration risk here is CROSS-VERSION: a file written under JDK 8's old
# platform-default charset (historically windows-1252 on Western European Windows)
# gets silently misread once the reader defaults to UTF-8 (JDK 18+). It is not a
# same-process round-trip bug -- write and read with the SAME JDK and the SAME
# (unforced) default always agree with themselves, which is why an earlier version
# of this test only reproduced on hosts whose locale happened to already be non-UTF-8
# (see NOTES.md for the two iterations that got this test to its current form).
#
# So: write with JDK 8, explicitly forcing -Dfile.encoding=windows-1252 to simulate
# the historically-affected platform deterministically, regardless of the actual
# host machine's locale. Then read the SAME file with JDK 25's own, unforced,
# always-UTF-8 default. That's the real bug, and it reproduces on every platform.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -f out.txt Write8.class Read25.class

echo "Write with JDK 8 (forced -Dfile.encoding=windows-1252, simulating the historical Windows default):"
"$JDK8_HOME/bin/javac" Write8.java
write_out="$("$JDK8_HOME/bin/java" -Dfile.encoding=windows-1252 Write8 2>&1)"
echo "$write_out" | sed 's/^/  /'

echo "Read that SAME file with JDK 25 (its own unforced default):"
"$JDK25_HOME/bin/javac" Read25.java
read_out="$("$JDK25_HOME/bin/java" Read25 2>&1)"
echo "$read_out" | sed 's/^/  /'

rm -f out.txt Write8.class Read25.class

if echo "$read_out" | grep -q "matches original = false" && echo "$read_out" | grep -q "U+FFFD"; then
  echo "REPRODUCED: JDK 8 wrote £ as a single windows-1252 byte; JDK 25's UTF-8 default can't decode it and substitutes U+FFFD (the replacement character)."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  echo "$read_out"
  exit 1
fi
