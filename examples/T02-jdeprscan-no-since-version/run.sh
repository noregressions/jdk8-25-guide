#!/usr/bin/env bash
# T02 -- jdeprscan tells you WHAT, never WHEN.
#
# Pins jdeprscan's actual output vocabulary, because it is narrower than it looks.
# Its only annotation is the bare string "(forRemoval=true)": no deprecation
# release, no removal release, no behaviour-change release. Every finding carries
# the same four words whether it has been on the removal path since JDK 9 or
# since JDK 24.
#
# That shapes the workflow. jdeprscan gives you a list of call sites; the release
# each one was deprecated in, and the release where it actually breaks, are a
# separate manual lookup -- which is the job Parts 2 and 3 of the guide do.
#
# Also pins the --for-removal filter (which findings it drops) and the documented
# restriction that --for-removal is rejected for --release 6/7/8 -- a real trap in
# a JDK 8 migration, where 8 is the obvious release to ask about.
set -uo pipefail
: "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out; mkdir -p out

"$JDK25_HOME/bin/javac" -nowarn -d out Deprecated02.java 2>/dev/null

echo "jdeprscan --for-removal:"
forremoval="$("$JDK25_HOME/bin/jdeprscan" --for-removal out 2>&1)"
echo "$forremoval" | sed 's/^/  /'

echo ""
echo "jdeprscan (no filter):"
allout="$("$JDK25_HOME/bin/jdeprscan" out 2>&1)"
echo "$allout" | sed 's/^/  /'

echo ""
echo "jdeprscan --release 8 --for-removal:"
rel8="$("$JDK25_HOME/bin/jdeprscan" --release 8 --for-removal out 2>&1 | head -2)"
rel8_rc=0; "$JDK25_HOME/bin/jdeprscan" --release 8 --for-removal out >/dev/null 2>&1 || rel8_rc=$?
echo "$rel8" | sed 's/^/  /'
echo "  [exit code $rel8_rc, no diagnostic message -- just a usage dump]"

rm -rf out

# 1. No "since" anywhere in either scan.
since_hits=$(printf '%s\n%s\n' "$forremoval" "$allout" | grep -ci "since" || true)
# 2. The only annotation actually emitted is the bare (forRemoval=true).
bare=$(echo "$forremoval" | grep -c "(forRemoval=true)$" || true)
# 3. --for-removal filters out the ordinary deprecation; the unfiltered run keeps it.
exec_filtered=$(echo "$forremoval" | grep -c "Runtime::exec" || true)
exec_unfiltered=$(echo "$allout"   | grep -c "Runtime::exec" || true)
# 4. --for-removal is refused for release 8 -- signalled ONLY by a non-zero exit
#    code plus a bare usage dump on stderr. No diagnostic text is printed at all.

echo ""
echo "occurrences of 'since' in jdeprscan output ....... $since_hits"
echo "findings annotated exactly '(forRemoval=true)' ... $bare"
echo "Runtime::exec with --for-removal ................. $exec_filtered"
echo "Runtime::exec without --for-removal .............. $exec_unfiltered"
echo "--release 8 --for-removal exit code .............. $rel8_rc"

ok=1
[ "$since_hits" = "0" ]    || { echo "MISMATCH: jdeprscan emitted a 'since' version after all ($since_hits lines)"; ok=0; }
[ "$bare" -ge 3 ]          || { echo "MISMATCH: expected >=3 bare '(forRemoval=true)' findings, got $bare"; ok=0; }
[ "$exec_filtered" = "0" ] || { echo "MISMATCH: --for-removal should have filtered out Runtime::exec"; ok=0; }
[ "$exec_unfiltered" -ge 1 ] || { echo "MISMATCH: unfiltered scan should still report Runtime::exec"; ok=0; }
[ "$rel8_rc" != "0" ]      || { echo "MISMATCH: --release 8 --for-removal was expected to fail, exited $rel8_rc"; ok=0; }

echo ""
if [ "$ok" = "1" ]; then
  echo "REPRODUCED: jdeprscan annotates findings '(forRemoval=true)' and nothing more -- no deprecation release, no removal release, no behaviour-change release. The tool answers WHAT; the WHEN is a manual lookup. Confirmed too that --for-removal is what separates the two deprecation tiers (Runtime.exec(String) is ordinary @Deprecated and drops out of the filtered scan), and that --for-removal is refused outright for --release 8 -- silently, via exit code $rel8_rc and a bare usage dump, with no message saying why."
  exit 0
else
  echo "DID NOT REPRODUCE the documented behaviour -- investigate."
  exit 1
fi
