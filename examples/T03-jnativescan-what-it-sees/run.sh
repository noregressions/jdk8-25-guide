#!/usr/bin/env bash
# T03 -- what jnativescan actually sees, and what it actually misses.
#
# jnativescan reports two different things, per its own help text: "restricted
# method calls and 'native' method declarations". The restricted-call half is the
# reason the tool was added in JDK 24, and it means code reaching FFM purely at
# runtime -- no `native` keyword anywhere -- is found rather than missed.
#
# Two classes performing the SAME restricted operation, to draw the real boundary:
#   Nat.java  -- a declared native method AND an ordinary compiled FFM downcall.
#                Both are found, and labelled differently.
#   Refl.java -- the same FFM downcall reached reflectively, every type resolved by
#                name. Found by nothing, because it leaves no constant-pool trace.
#
# The reflective case is the genuine limit, and it is the same static-analysis
# boundary chapter 1.1 draws for jdeps. Also checks that MethodHandles.Lookup has
# no findNative method, since that name circulates as an FFM entry point -- the
# real ones are on java.lang.foreign.SymbolLookup.
set -uo pipefail
: "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out-nat out-refl; mkdir -p out-nat out-refl

"$JDK25_HOME/bin/javac" -d out-nat  Nat.java  2>/dev/null
"$JDK25_HOME/bin/javac" -d out-refl Refl.java 2>/dev/null

echo "Does java.lang.invoke.MethodHandles\$Lookup declare findNative?"
lookup_members="$("$JDK25_HOME/bin/javap" 'java.lang.invoke.MethodHandles$Lookup' 2>&1)"
findnative_count=$(echo "$lookup_members" | grep -c "findNative" || true)
echo "  matches for 'findNative' in MethodHandles.Lookup: $findnative_count"
echo "  (the real FFM entry points are on java.lang.foreign.SymbolLookup:)"
"$JDK25_HOME/bin/javap" java.lang.foreign.SymbolLookup 2>&1 | grep -E "find|libraryLookup|loaderLookup" | sed 's/^/    /'

echo ""
echo "jnativescan on Nat (declared native method + runtime-only FFM downcall):"
nat="$("$JDK25_HOME/bin/jnativescan" --class-path out-nat 2>&1)"
echo "$nat" | sed 's/^/  /'

echo ""
echo "jnativescan on Refl (same FFM downcall, resolved reflectively by name):"
refl="$("$JDK25_HOME/bin/jnativescan" --class-path out-refl 2>&1)"
echo "$refl" | sed 's/^/  /'

echo ""
echo "jnativescan --print-native-access on Nat:"
pna="$("$JDK25_HOME/bin/jnativescan" --class-path out-nat --print-native-access 2>&1)"
echo "  $pna"

rm -rf out-nat out-refl

nat_declared=$(echo "$nat"  | grep -c "is a native method declaration" || true)
nat_restricted=$(echo "$nat" | grep -c "references restricted methods" || true)
refl_none=$(echo "$refl" | grep -c "no restricted methods" || true)

ok=1
[ "$findnative_count" = "0" ] || { echo "MISMATCH: MethodHandles.Lookup unexpectedly declares findNative"; ok=0; }
[ "$nat_declared"  -ge 1 ]    || { echo "MISMATCH: jnativescan did not report the declared native method"; ok=0; }
[ "$nat_restricted" -ge 1 ]   || { echo "MISMATCH: jnativescan did not report the FFM restricted call"; ok=0; }
[ "$refl_none"     -ge 1 ]    || { echo "MISMATCH: expected '<no restricted methods>' for the reflective class"; ok=0; }
[ "$pna" = "ALL-UNNAMED" ]    || { echo "MISMATCH: --print-native-access printed '$pna', expected bare 'ALL-UNNAMED'"; ok=0; }

echo ""
if [ "$ok" = "1" ]; then
  echo "REPRODUCED: jnativescan reports BOTH the declared native method and the FFM restricted call reached only at runtime, in one scan, labelled differently -- so runtime-only FFM access is found, not missed. What it genuinely misses is the same thing jdeps misses: a restricted method resolved reflectively by name, which leaves nothing in the constant pool to scan. Confirmed also that MethodHandles.Lookup declares no findNative method (the real FFM lookups are on java.lang.foreign.SymbolLookup), and that --print-native-access prints the bare value 'ALL-UNNAMED' for substitution straight into a flag."
  exit 0
else
  echo "DID NOT REPRODUCE the documented behaviour -- investigate."
  exit 1
fi
