#!/usr/bin/env bash
# Runs every discovery test case under both JDK 8 and JDK 25, reports which ones
# reproduced the documented JDK 8 -> 25 behaviour difference.
#
# Usage:
#   ./setup/download-jdks.sh   # once, fetches Temurin 8 + 25 into .jdks/
#   ./run-all.sh               # run every NN-slug/ (Part 3) and TNN-slug/ (Part 1 tools) test case
#   ./run-all.sh 05 18         # run only specific test numbers
#   ./run-all.sh T02           # tool tests are numbered TNN, where TNN maps to chapter 1.NN
#   ./run-all.sh M00           # migration tests are MNN; M00 spans all of Part 2
#
# A test that exits 2 (skipped) may print "SKIP-REASON: <short reason>"; that reason
# is shown in the summary instead of a generic message.
#
# Each test is killed if it runs longer than TEST_TIMEOUT seconds (default 120).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

# JAVA_TOOL_OPTIONS may be set by the ambient shell (sandbox proxy config, CI, etc.) —
# unset it for the child java invocations so tests see clean, real-world behaviour.
unset JAVA_TOOL_OPTIONS

# Resolve a JDK home for each major version, in order of preference:
#   1. an explicit JDK8_HOME / JDK25_HOME from the environment
#   2. a path recorded by setup/download-jdks.sh
#   3. whatever setup/find-jdk.sh can locate on this machine
# Step 3 means ./run-all.sh usually works with no setup at all, on any platform.
resolve_jdk() {
  local major="$1"
  local cur="$2"
  local recorded
  if [ -n "$cur" ]; then
    if [ -x "$cur/bin/javac" ]; then printf '%s\n' "$cur"; return 0; fi
    # Don't silently substitute for an explicit setting that turned out to be wrong.
    echo "warning: JDK${major}_HOME=$cur has no bin/javac; falling back to discovery" >&2
    cur=""
  fi
  recorded="$ROOT/.jdks/jdk$major.path"
  if [ -f "$recorded" ]; then
    read -r cur < "$recorded"
    if [ -n "$cur" ] && [ -x "$cur/bin/javac" ]; then printf '%s\n' "$cur"; return 0; fi
  fi
  "$ROOT/setup/find-jdk.sh" "$major" 2>/dev/null
}

JDK8_HOME="$(resolve_jdk 8 "${JDK8_HOME:-}")"
JDK25_HOME="$(resolve_jdk 25 "${JDK25_HOME:-}")"
export JDK8_HOME JDK25_HOME

missing=""
[ -x "${JDK8_HOME:-}/bin/javac" ]  || missing="$missing JDK 8"
[ -x "${JDK25_HOME:-}/bin/javac" ] || missing="$missing JDK 25"
if [ -n "$missing" ]; then
  cat >&2 <<MSG
Could not find a usable JDK for:$missing

The tests compile as well as run, so a full JDK is needed, not a JRE. Either:

  ./setup/download-jdks.sh            # find local installs, or fetch from Adoptium
  JDK8_HOME=... JDK25_HOME=... $0     # point at specific installs
MSG
  exit 1
fi

echo "JDK8_HOME  = $JDK8_HOME  ($("$JDK8_HOME/bin/java" -version 2>&1 | head -1))"
echo "JDK25_HOME = $JDK25_HOME  ($("$JDK25_HOME/bin/java" -version 2>&1 | head -1))"
echo ""

# Per-test watchdog. A test that blocks forever would otherwise stall the whole
# suite with no output, which is exactly how a non-daemon worker thread outliving
# main presents itself. `timeout` is not present on macOS by default, so this is a
# portable equivalent: run the test in the background, poll for the deadline, and
# kill the whole process group if it expires.
TEST_TIMEOUT="${TEST_TIMEOUT:-120}"

run_with_timeout() {  # run_with_timeout <dir> ; stdout = test output, rc 124 = timed out
  local dir="$1"
  local out rc pid waited
  out="$(mktemp)"
  # Job control gives the child its own process group, so on timeout the whole tree
  # can be signalled -- otherwise a killed test orphans its JVMs, which then linger
  # and can interfere with later tests.
  set -m
  ( cd "$dir" && exec ./run.sh ) >"$out" 2>&1 &
  pid=$!
  set +m
  waited=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$waited" -ge "$TEST_TIMEOUT" ]; then
      kill -TERM "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null
      sleep 2
      kill -KILL "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
      cat "$out"; rm -f "$out"
      return 124
    fi
    sleep 1
    waited=$((waited+1))
  done
  wait "$pid"; rc=$?
  cat "$out"; rm -f "$out"
  return $rc
}

FILTER=("$@")
declare -a RESULTS
reason=""

for dir in "$ROOT"/[0-9][0-9]-*/ "$ROOT"/M[0-9][0-9]-*/ "$ROOT"/T[0-9][0-9]-*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  num="${name%%-*}"

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
  out="$(run_with_timeout "$dir")"
  code=$?
  echo "$out" | sed 's/^/  /'
  if [ $code -eq 0 ]; then
    RESULTS+=("$name|PASS|reproduced the documented difference")
  elif [ $code -eq 2 ]; then
    # A skipping test can name its own reason with a "SKIP-REASON: ..." line, so the
    # summary says why without anyone scrolling back through the full output.
    reason="$(printf '%s\n' "$out" | sed -n 's/^SKIP-REASON: *//p' | head -1)"
    RESULTS+=("$name|SKIP|${reason:-environment not available in this run (see output above)}")
  elif [ $code -eq 124 ]; then
    echo "  !! killed after ${TEST_TIMEOUT}s"
    RESULTS+=("$name|TIMEOUT|exceeded ${TEST_TIMEOUT}s and was killed — investigate")
  else
    RESULTS+=("$name|FAIL|did NOT reproduce the documented difference — investigate")
  fi
  echo ""
done

echo "═══════════════════════════════════════════════════"
echo "SUMMARY"
echo "═══════════════════════════════════════════════════"
pass=0; fail=0; skip=0; timeout=0
for r in "${RESULTS[@]}"; do
  IFS='|' read -r name status note <<< "$r"
  printf "%-45s %-7s %s\n" "$name" "$status" "$note"
  case "$status" in
    PASS) pass=$((pass+1));;
    FAIL) fail=$((fail+1));;
    SKIP) skip=$((skip+1));;
    TIMEOUT) timeout=$((timeout+1)); fail=$((fail+1));;
  esac
done
echo "───────────────────────────────────────────────────"
if [ $timeout -gt 0 ]; then
  echo "$pass passed, $fail failed ($timeout timed out), $skip skipped"
else
  echo "$pass passed, $fail failed, $skip skipped"
fi
[ $fail -eq 0 ]
