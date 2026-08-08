#!/usr/bin/env bash
# 22 -- Finalisation weakened (deprecated JDK 9, forRemoval JDK 18 / JEP 421).
#
# finalize() itself still runs identically on both JDK 8 and JDK 25 today -- it's
# deprecated-for-removal, not yet removed, so a same-behaviour result on both JDKs
# is the CORRECT and expected result, not a false negative. The actual risk this
# item describes -- "resources not cleaned up, or cleaned up at unpredictable
# times" -- isn't something a short, deterministic test can safely assert on
# (finalization timing is inherently non-deterministic even when it works).
#
# What IS deterministic and demonstrable: finalization can be turned off entirely,
# right now, with a JVM flag -- which is the concrete shape of "still works today,
# on borrowed time" that the doc's Symptom line is getting at.
#
# Correction found while building this test: the reference doc's Detect column
# says "-Dfinalization=disabled" (a system property). The actual JDK 25 flag is
# "--finalization=disabled" (a launcher option, double-dash, no -D) -- verified
# below; -D system properties do NOT affect this at all.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 Fin.java
"$JDK25_HOME/bin/javac" -d out25 Fin.java 2>/dev/null

echo "JDK 8:"
j8_out="$("$JDK8_HOME/bin/java" -cp out8 Fin 2>&1)"
echo "$j8_out" | sed 's/^/  /'

echo "JDK 25 (default -- finalization still enabled, still works):"
j25_out="$("$JDK25_HOME/bin/java" -cp out25 Fin 2>&1)"
echo "$j25_out" | sed 's/^/  /'

echo "JDK 25 with --finalization=disabled (the actual flag; -D does NOT work):"
j25off_out="$("$JDK25_HOME/bin/java" --finalization=disabled -cp out25 Fin 2>&1)"
echo "$j25off_out" | sed 's/^/  /'

echo "JDK 25 with -Dfinalization=disabled (the doc's stated flag, as a control -- should NOT disable it):"
j25wrongflag_out="$("$JDK25_HOME/bin/java" -Dfinalization=disabled -cp out25 Fin 2>&1)"
echo "$j25wrongflag_out" | sed 's/^/  /'

rm -rf out8 out25

ok=true
echo "$j8_out" | grep -q "finalized = true" || ok=false
echo "$j25_out" | grep -q "finalized = true" || ok=false
echo "$j25off_out" | grep -q "finalized = false" || ok=false
echo "$j25wrongflag_out" | grep -q "finalized = true" || ok=false

if $ok; then
  echo "REPRODUCED: finalize() still runs identically on JDK 8 and JDK 25 today. --finalization=disabled (launcher option) turns it off entirely with a one-flag change; -Dfinalization=disabled (a system property, matching the reference doc's current wording) has NO effect -- the doc's Detect column names the wrong flag syntax."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
