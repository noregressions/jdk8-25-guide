#!/usr/bin/env bash
# 39 -- Reflective mutation of a final field (JEP 500, JDK 26).
#
# Writing to a final field through setAccessible(true) has been silent since JDK 8.
# From JDK 26 the JVM warns and says a future release will block it -- the same
# warn-then-deny sequence already applied to sun.misc.Unsafe and native access.
#
# Three checks: JDK 8 (silent), the target JDK (warns from 26), and the target with
# --illegal-final-field-mutation=deny, which turns the future hard failure on today.
# That flag does not exist before 26, so the third leg is skipped where unsupported
# rather than counted as a failure.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"

# JEP 500 is JDK 26, so against an earlier target there is no warning to find.
#
# The two harnesses want different answers to that, and both are right:
#
#   run-all.sh asks "did the documented difference reproduce?" A target that predates
#   the feature cannot answer, which is a skip -- the same as tests 37 and 38.
#
#   The release matrix asks "does this release still behave like JDK 8?" There the
#   negative is the finding: it is what puts 8-25 in the "silent" segment of the
#   timeline and fixes JDK 26 as the boundary. Skipping would discard it.
#
# The matrix exports TARGET_HOME; run-all.sh does not.
if [ -z "${TARGET_HOME:-}" ]; then
  target_major=$("$JDK25_HOME/bin/java" -version 2>&1 \
    | sed -n 's/.*version "\([0-9][0-9]*\)\..*/\1/p;s/.*version "1\.\([0-9][0-9]*\).*/\1/p' | head -1)
  if [ -n "$target_major" ] && [ "$target_major" -lt 26 ]; then
    echo "SKIP-REASON: JEP 500 lands in JDK 26; target is JDK $target_major"
    echo "SKIP: final-field mutation is silent before JDK 26, so there is no warning for"
    echo "this test to detect. Re-run with a JDK 26+ target:"
    echo "    JDK25_HOME=/path/to/jdk26 ./run.sh"
    exit 2
  fi
fi

rm -rf out8 outT; mkdir -p out8 outT

"$JDK8_HOME/bin/javac" -nowarn -d out8 FinalMutate.java 2>/dev/null
"$JDK25_HOME/bin/javac" -nowarn -d outT FinalMutate.java 2>/dev/null

echo "JDK 8:"
j8="$("$JDK8_HOME/bin/java" -cp out8 FinalMutate 2>&1)"; j8_exit=$?
echo "$j8" | sed 's/^/  /'; echo "  exit=$j8_exit"
j8_warn=$(echo "$j8" | grep -ci "final field.*mutated\|Mutating final fields" || true)

echo "Target JDK (default settings):"
jt="$("$JDK25_HOME/bin/java" -cp outT FinalMutate 2>&1)"; jt_exit=$?
echo "$jt" | sed 's/^/  /'; echo "  exit=$jt_exit"
jt_warn=$(echo "$jt" | grep -ci "final field.*mutated\|Mutating final fields" || true)

echo "Target JDK with --illegal-final-field-mutation=deny (tomorrow, today):"
if "$JDK25_HOME/bin/java" --illegal-final-field-mutation=deny -version >/dev/null 2>&1; then
  jd="$("$JDK25_HOME/bin/java" --illegal-final-field-mutation=deny -cp outT FinalMutate 2>&1)"; jd_exit=$?
  echo "$jd" | head -3 | sed 's/^/  /'; echo "  exit=$jd_exit"
  deny_supported=1
else
  echo "  flag not supported on this release (JEP 500 is JDK 26) -- leg skipped"
  deny_supported=0; jd=""; jd_exit=0
fi

rm -rf out8 outT

ok=1
[ "$j8_exit" -eq 0 ]  || { echo "MISMATCH: the mutation should succeed on JDK 8"; ok=0; }
[ "$j8_warn" -eq 0 ]  || { echo "MISMATCH: JDK 8 should say nothing about final fields"; ok=0; }
[ "$jt_warn" -ge 1 ]  || ok=0
[ "$jt_exit" -eq 0 ]  || { echo "MISMATCH: the target should still allow the mutation, only warn"; ok=0; }
if [ "$deny_supported" = "1" ]; then
  [ "$jd_exit" -ne 0 ] || { echo "MISMATCH: =deny was expected to fail the mutation"; ok=0; }
fi

echo ""
if [ "$ok" = "1" ]; then
  echo "REPRODUCED: reflective mutation of a final field is silent on JDK 8 and warns on the target, which still permits it -- JEP 500's warn phase. The mutation itself keeps working, so nothing fails today; --illegal-final-field-mutation=deny turns the announced future behaviour on now, the same way --sun-misc-unsafe-memory-access=deny does for Unsafe."
  exit 0
else
  echo "DID NOT REPRODUCE: the target JDK did not warn about final-field mutation, which is expected on any release before 26 (JEP 500)."
  exit 1
fi
