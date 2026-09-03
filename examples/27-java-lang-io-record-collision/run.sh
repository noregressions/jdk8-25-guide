#!/usr/bin/env bash
# 27 -- java.lang.IO (JEP 512, JDK 25) collides with user classes named IO --
# but ONLY via a wildcard import -- a single-type import still wins. This test
# verifies that correction directly: same class name, same JDK 25, wildcard
# import fails, explicit single-type import doesn't.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

"$JDK25_HOME/bin/javac" -d out25 mypkg/IO.java mypkg/Record.java

echo "JDK 25, wildcard import (import mypkg.*):"
wild_out="$("$JDK25_HOME/bin/javac" -d out25 -cp out25 UseWildcard.java 2>&1)"; wild_exit=$?
echo "$wild_out" | sed 's/^/  /'
echo "  exit=$wild_exit"

echo "JDK 25, explicit single-type import (import mypkg.IO):"
exp_out="$("$JDK25_HOME/bin/javac" -d out25 -cp out25 UseExplicit.java 2>&1)"; exp_exit=$?
echo "$exp_out" | sed 's/^/  /'
echo "  exit=$exp_exit"

echo "JDK 8, wildcard import (java.lang.IO doesn't exist yet -- control):"
"$JDK8_HOME/bin/javac" -d out8 mypkg/IO.java mypkg/Record.java
j8_out="$("$JDK8_HOME/bin/javac" -d out8 -cp out8 UseWildcard.java 2>&1)"; j8_exit=$?
echo "$j8_out" | sed 's/^/  /'
echo "  exit=$j8_exit"

echo "JDK 25, wildcard import, SAME collision pattern with java.lang.Record (JEP 395, JDK 16 -- one cycle before IO):"
rec_out="$("$JDK25_HOME/bin/javac" -d out25 -cp out25 UseWildcardRecord.java 2>&1)"; rec_exit=$?
echo "$rec_out" | sed 's/^/  /'
echo "  exit=$rec_exit"

echo "JDK 25, same-package reference (no import at all -- mypkg's own types shadow java.lang):"
same_out="$("$JDK25_HOME/bin/javac" -d out25 -cp out25 mypkg/SamePkg.java 2>&1)"; same_exit=$?
[ -n "$same_out" ] && echo "$same_out" | sed 's/^/  /'
same_run="$("$JDK25_HOME/bin/java" -cp out25 mypkg.SamePkg 2>&1)"
echo "  compile exit=$same_exit, run output: $same_run"

rm -rf out8 out25

ok=true
[ "$wild_exit" -ne 0 ] || ok=false
# Third path: same-package must compile AND resolve to the user's class, not java.lang's.
[ "$same_exit" -eq 0 ] || { echo "MISMATCH: same-package reference should compile cleanly"; ok=false; }
echo "$same_run" | grep -q "mypkg.IO.hello" || { echo "MISMATCH: same-package reference should resolve to mypkg.IO"; ok=false; }
echo "$wild_out" | grep -q "ambiguous" || ok=false
[ "$exp_exit" -eq 0 ] || ok=false
[ "$j8_exit" -eq 0 ] || ok=false
[ "$rec_exit" -ne 0 ] || ok=false
echo "$rec_out" | grep -q "ambiguous" || ok=false

if $ok; then
  echo "ALL THREE PATHS CONFIRMED: the collision is narrower than \"any class named IO breaks\". A wildcard import from another package is ambiguous and fails; an explicit single-type import compiles (a specific import beats an on-demand one); and a same-package reference compiles and resolves to the user's own class, because the package's own types shadow java.lang."
  echo "REPRODUCED: a wildcard-imported user class named IO becomes ambiguous against java.lang.IO on JDK 25 (compile error); the identical class via an explicit single-type import compiles cleanly; the same wildcard import was never a problem on JDK 8 (java.lang.IO didn't exist yet); and the identical pattern reproduces with java.lang.Record, one JDK cycle earlier -- so this is one recurring pattern that arrives with each new java.lang type, not two unrelated incidents."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
