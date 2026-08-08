#!/usr/bin/env bash
# 03 -- Obsolete GC logging flags (JEP 158/271 unified logging).
#
# This test checks THREE flags, not one, because the reference doc's blanket claim
# ("PrintGCDetails, PrintGCTimeStamps and the rest of the PrintGC* family:
# unrecognised, fatal") turned out to be too coarse once tested empirically:
#
#   -XX:+PrintGCDetails     -> JDK 25 keeps this as a DEPRECATED ALIAS. It prints a
#                              warning and translates to -Xlog:gc* automatically.
#                              NOT fatal. (Matches the deck's own correction about
#                              -verbose:gc, which is a sibling alias -- but the deck
#                              groups PrintGCDetails with the flags that ARE fatal.)
#   -XX:+PrintGCTimeStamps  -> genuinely fatal: "Unrecognized VM option", VM refuses
#                              to start. This one IS in the PrintGC* family the doc
#                              describes.
#   -verbose:gc             -> also a kept, working alias (per the deck's own
#                              correction) -- included here as a control.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"

check() {
  local flag="$1" jdk_home="$2" jdk_label="$3"
  local out exit
  out="$("$jdk_home/bin/java" "$flag" -version 2>&1)"
  exit=$?
  echo "  $jdk_label $flag -> exit=$exit"
  echo "$out" | head -1 | sed 's/^/    /'
}

echo "-XX:+PrintGCDetails:"
check "-XX:+PrintGCDetails" "$JDK8_HOME" "JDK8 "
d25_details="$("$JDK25_HOME/bin/java" -XX:+PrintGCDetails -version 2>&1)"; d25_details_exit=$?
check "-XX:+PrintGCDetails" "$JDK25_HOME" "JDK25"

echo "-XX:+PrintGCTimeStamps:"
check "-XX:+PrintGCTimeStamps" "$JDK8_HOME" "JDK8 "
d25_ts="$("$JDK25_HOME/bin/java" -XX:+PrintGCTimeStamps -version 2>&1)"; d25_ts_exit=$?
check "-XX:+PrintGCTimeStamps" "$JDK25_HOME" "JDK25"

echo "-verbose:gc:"
check "-verbose:gc" "$JDK8_HOME" "JDK8 "
check "-verbose:gc" "$JDK25_HOME" "JDK25"

ok=true
# PrintGCDetails must survive (deprecated alias, not fatal) on JDK 25
[ "$d25_details_exit" -eq 0 ] || ok=false
echo "$d25_details" | grep -qi "deprecated" || ok=false
# PrintGCTimeStamps must be fatal on JDK 25
[ "$d25_ts_exit" -ne 0 ] || ok=false
echo "$d25_ts" | grep -q "Unrecognized VM option" || ok=false

if $ok; then
  echo "REPRODUCED: -XX:+PrintGCDetails survives on JDK 25 as a deprecated, working alias (translated to -Xlog:gc*)."
  echo "REPRODUCED: -XX:+PrintGCTimeStamps is genuinely fatal on JDK 25 (Unrecognized VM option)."
  echo "NOTE: the reference doc's item #3 groups these together as equally fatal -- that's too coarse. Only some of the PrintGC* family is actually startup-fatal; PrintGCDetails itself is not."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
