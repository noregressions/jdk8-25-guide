#!/usr/bin/env bash
# 05 -- Reflection on JDK internals: setAccessible(true) on a JDK-internal field.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"

mkdir -p /tmp/reflect8 /tmp/reflect25

echo "JDK 8:"
"$JDK8_HOME/bin/javac" -d /tmp/reflect8 Reflect.java
out8="$("$JDK8_HOME/bin/java" -cp /tmp/reflect8 Reflect 2>&1)"; code8=$?
echo "$out8" | sed 's/^/  /'
echo "  exit=$code8"

echo "JDK 25:"
"$JDK25_HOME/bin/javac" -d /tmp/reflect25 Reflect.java
out25="$("$JDK25_HOME/bin/java" -cp /tmp/reflect25 Reflect 2>&1)"; code25=$?
echo "$out25" | sed 's/^/  /'
echo "  exit=$code25"

# --- The two escape hatches, one of which does nothing ---------------------------
# --add-opens is the real one: it restores *access*. Note what it does not restore --
# the field is byte[] on JDK 25 and char[] on JDK 8 (compact strings, JDK 9), so code
# that got past setAccessible and then cast to char[] still fails. "Restores JDK 8
# behaviour" is true of the permission and false of the data.
#
# --illegal-access=permit is the one to be careful about. It is not rejected on JDK 25
# and it does not fail the launch: it is accepted, warned about, and ignored. Anyone
# who adds it, sees the VM start, and assumes illegal access is re-enabled is wrong.
echo "JDK 25 with --add-opens java.base/java.lang=ALL-UNNAMED:"
open25="$("$JDK25_HOME/bin/java" --add-opens java.base/java.lang=ALL-UNNAMED -cp /tmp/reflect25 Reflect 2>&1)"; open25_exit=$?
echo "$open25" | sed 's/^/  /'
echo "  exit=$open25_exit"

echo "JDK 25 with --illegal-access=permit (removed in 17 -- what happens now?):"
ia25="$("$JDK25_HOME/bin/java" --illegal-access=permit -cp /tmp/reflect25 Reflect 2>&1)"; ia25_exit=$?
echo "$ia25" | sed 's/^/  /'
echo "  exit=$ia25_exit"

rm -rf /tmp/reflect8 /tmp/reflect25

ok=1
[ "$code8" -eq 0 ] || { echo "MISMATCH: JDK 8 should allow the access"; ok=0; }
[ "$code25" -ne 0 ] || { echo "MISMATCH: JDK 25 should throw"; ok=0; }
echo "$out25" | grep -q "InaccessibleObjectException" || { echo "MISMATCH: expected InaccessibleObjectException"; ok=0; }
# --add-opens restores access...
[ "$open25_exit" -eq 0 ] || { echo "MISMATCH: --add-opens should restore access"; ok=0; }
# ...but the field type is still byte[], not the char[] JDK 8 reported.
echo "$out8"   | grep -q '\[C' || { echo "MISMATCH: JDK 8 should report a char[] field"; ok=0; }
echo "$open25" | grep -q '\[B' || { echo "MISMATCH: JDK 25 should report a byte[] field even with --add-opens"; ok=0; }
# --illegal-access=permit neither works nor fails: it is ignored.
[ "$ia25_exit" -ne 0 ] || { echo "MISMATCH: --illegal-access=permit should NOT have restored access"; ok=0; }
echo "$ia25" | grep -qi "Ignoring option --illegal-access" || { echo "MISMATCH: expected an 'Ignoring option' warning"; ok=0; }

echo ""
if [ "$ok" = "1" ]; then
  echo "REPRODUCED: JDK 8 allows the reflective access; JDK 25 throws InaccessibleObjectException."
  echo "ALSO REPRODUCED: --add-opens java.base/java.lang=ALL-UNNAMED restores the access -- but not the data shape. JDK 8 reports the field as char[] and JDK 25 as byte[] (compact strings, JDK 9), so code that reflected past setAccessible and then cast to char[] breaks even with the flag."
  echo "ALSO REPRODUCED: --illegal-access=permit is NOT a startup failure on JDK 25. The VM prints \"Ignoring option --illegal-access=permit; support was removed in 17.0\", starts normally, and still throws -- so it neither helps nor announces itself as useless by failing. That is the trap: it looks like it was accepted."
  exit 0
else
  echo "DID NOT REPRODUCE the documented behaviour -- investigate."
  exit 1
fi
