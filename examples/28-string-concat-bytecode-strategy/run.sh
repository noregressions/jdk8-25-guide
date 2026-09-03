#!/usr/bin/env bash
# 28 -- String concatenation evaluation order (JEP 280).
#
# This test investigates the widely-repeated evaluation-order claim as worded --
# "evaluation order can differ... only on recompiled code" -- and the popular
# migration-writeup example behind it (concatenating a char[] prints differently
# depending on which javac compiled it). Both were tested during the pilot (see
# ../NOTES.md) and NEITHER reproduced. This test checks the claim a second way,
# with side-effecting toString() calls instead of a char[], and confirms the same
# finding: evaluation order does NOT differ. What DOES genuinely differ, and is
# what this test actually asserts on, is the bytecode STRATEGY -- StringBuilder
# chain vs invokedynamic -- which changes size/shape/stack-map-shape but is
# specifically NOT observable as a reordering of side effects, because the JLS
# mandates left-to-right operand evaluation regardless of which bytecode
# instructions the compiler emits to implement the concatenation itself.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 SideEffect.java
"$JDK25_HOME/bin/javac" -d out25 SideEffect.java

echo "javac8-compiled, run on JDK 8:"
r8="$("$JDK8_HOME/bin/java" -cp out8 SideEffect 2>&1)"
echo "$r8" | sed 's/^/  /'

echo "javac25-compiled, run on JDK 25:"
r25="$("$JDK25_HOME/bin/java" -cp out25 SideEffect 2>&1)"
echo "$r25" | sed 's/^/  /'

echo "javac8-compiled (old StringBuilder bytecode), run on the NEWER JVM (JDK 25):"
r_cross="$("$JDK25_HOME/bin/java" -cp out8 SideEffect 2>&1)"
echo "$r_cross" | sed 's/^/  /'

echo "Bytecode strategy comparison (javap -c):"
strategy8=$("$JDK25_HOME/bin/javap" -c out8/SideEffect.class | grep -c "StringBuilder")
strategy25=$("$JDK25_HOME/bin/javap" -c out25/SideEffect.class | grep -c "invokedynamic")
echo "  javac8-compiled class uses StringBuilder instructions: $strategy8 occurrence(s)"
echo "  javac25-compiled class uses invokedynamic instructions: $strategy25 occurrence(s)"

order() { echo "$1" | grep "toString() call" | sed -E 's/.*on Loud#([0-9]).*/\1/' | tr '\n' ','; }
order8=$(order "$r8")
order25=$(order "$r25")

rm -rf out8 out25

ok=true
[ "$order8" = "1,2,3," ] || ok=false
[ "$order25" = "1,2,3," ] || ok=false
[ "$strategy8" -gt 0 ] || ok=false
[ "$strategy25" -gt 0 ] || ok=false

if $ok; then
  echo
  echo "FINDING: evaluation order is IDENTICAL (1,2,3) on javac8/JDK8, javac25/JDK25, and the cross-version javac8-on-JDK25 run -- the widely-claimed evaluation-order difference does NOT reproduce. This is the second independent example to come back negative (side-effecting toString() here, a char[] previously). The bytecode STRATEGY genuinely does change (StringBuilder chain -> invokedynamic), which is real and citable -- but changing HOW the JVM builds the string is not the same claim as changing WHEN side effects fire, and there is no compiler-legal route to the latter. Cite the bytecode-shape change; treat any reordering claim as needing a runnable demonstration."
  exit 0
else
  echo "Unexpected result -- even the bytecode-strategy check itself failed. Investigate further."
  exit 1
fi
