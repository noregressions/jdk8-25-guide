#!/usr/bin/env bash
# Runs every discovery test case under both JDK 8 and JDK 25, reports which ones
# reproduced the documented JDK 8 -> 25 behaviour difference.
#
# Usage:
#   ./setup/download-jdks.sh   # once, fetches Temurin 8 + 25 into .jdks/
#   ./run-all.sh               # run every NN-slug/ test case
#   ./run-all.sh 05 18         # run only specific test numbers
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

export JDK8_HOME="${JDK8_HOME:-$ROOT/.jdks/jdk8}"
export JDK25_HOME="${JDK25_HOME:-$ROOT/.jdks/jdk25}"

# JAVA_TOOL_OPTIONS may be set by the ambient shell (sandbox proxy config, CI, etc.) —
# unset it for the child java invocations so tests see clean, real-world behaviour.
unset JAVA_TOOL_OPTIONS

if [ ! -x "$JDK8_HOME/bin/java" ] || [ ! -x "$JDK25_HOME/bin/java" ]; then
  echo "JDKs not found. Run ./setup/download-jdks.sh first (or set JDK8_HOME / JDK25_HOME)." >&2
  exit 1
fi

echo "JDK8_HOME  = $JDK8_HOME  ($("$JDK8_HOME/bin/java" -version 2>&1 | head -1))"
echo "JDK25_HOME = $JDK25_HOME  ($("$JDK25_HOME/bin/java" -version 2>&1 | head -1))"
echo ""

FILTER=("$@")
declare -a RESULTS

for dir in "$ROOT"/[0-9][0-9]-*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  num="${name:0:2}"

  if [ ${#FILTER[@]} -gt 0 ]; then
    match=0
    for f in "${FILTER[@]}"; do [ "$f" = "$num" ] && match=1; done
    [ "$match" = 1 ] || continue
  fi

  if [ ! -x "$dir/run.sh" ]; then
    RESULTS+=("$name|SKIP|no run.sh")
    continue
  fi

  echo "── $name ─────────────────────────────────────────"
  out="$(cd "$dir" && ./run.sh 2>&1)"
  code=$?
  echo "$out" | sed 's/^/  /'
  if [ $code -eq 0 ]; then
    RESULTS+=("$name|PASS|reproduced the documented difference")
  elif [ $code -eq 2 ]; then
    RESULTS+=("$name|SKIP|environment not available in this run (see output above)")
  else
    RESULTS+=("$name|FAIL|did NOT reproduce the documented difference — investigate")
  fi
  echo ""
done

echo "═══════════════════════════════════════════════════"
echo "SUMMARY"
echo "═══════════════════════════════════════════════════"
pass=0; fail=0; skip=0
for r in "${RESULTS[@]}"; do
  IFS='|' read -r name status note <<< "$r"
  printf "%-45s %-5s %s\n" "$name" "$status" "$note"
  case "$status" in
    PASS) pass=$((pass+1));;
    FAIL) fail=$((fail+1));;
    SKIP) skip=$((skip+1));;
  esac
done
echo "───────────────────────────────────────────────────"
echo "$pass passed, $fail failed, $skip skipped"
[ $fail -eq 0 ]
