#!/usr/bin/env bash
# 03 -- Obsolete GC logging flags (JEP 158/271 unified logging).
#
# This test checks THREE flags, not one, because the PrintGC* family did not all go
# the same way and treating it as one bucket gets two of these three wrong:
#
#   -XX:+PrintGCDetails     -> JDK 25 keeps this as a DEPRECATED ALIAS. It prints a
#                              warning and translates to -Xlog:gc* automatically.
#                              NOT fatal.
#   -XX:+PrintGCTimeStamps  -> genuinely fatal: "Unrecognized VM option", VM refuses
#                              to start.
#   -verbose:gc             -> also a kept, working alias -- included here as a
#                              control, since it is PrintGCDetails' sibling.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
WORKDIR=gclogs; mkdir -p "$WORKDIR"; trap 'rm -rf "$WORKDIR"' EXIT

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

# -Xloggc is the fourth flag any grep for GC logging turns up, and it belongs in the
# survivors column with -verbose:gc and PrintGCDetails -- a deprecated alias that
# still works and translates itself to -Xlog:gc:<file>. Included because a config
# audit that finds it needs to know which bucket it is in.
echo "-Xloggc:<file>:"
check "-Xloggc:$WORKDIR/gc8.log"  "$JDK8_HOME"  "JDK8 "
d25_loggc="$("$JDK25_HOME/bin/java" "-Xloggc:$WORKDIR/gc25.log" -version 2>&1)"; d25_loggc_exit=$?
check "-Xloggc:$WORKDIR/gc25.log" "$JDK25_HOME" "JDK25"

ok=true
# PrintGCDetails must survive (deprecated alias, not fatal) on JDK 25
[ "$d25_details_exit" -eq 0 ] || ok=false
echo "$d25_details" | grep -qi "deprecated" || ok=false
# PrintGCTimeStamps must be fatal on JDK 25
[ "$d25_ts_exit" -ne 0 ] || ok=false
echo "$d25_ts" | grep -q "Unrecognized VM option" || ok=false
# -Xloggc must survive as a deprecated alias too
[ "$d25_loggc_exit" -eq 0 ] || ok=false
echo "$d25_loggc" | grep -qi "deprecated" || ok=false

if $ok; then
  echo "REPRODUCED: -XX:+PrintGCDetails survives on JDK 25 as a deprecated, working alias (translated to -Xlog:gc*)."
  echo "REPRODUCED: -XX:+PrintGCTimeStamps is genuinely fatal on JDK 25 (Unrecognized VM option)."
  echo "REPRODUCED: -Xloggc:<file> also survives as a deprecated alias, translating to -Xlog:gc:<file>."
  echo "NOTE: the PrintGC* family cannot be treated as one bucket. Only part of it is startup-fatal; PrintGCDetails and -verbose:gc survive as kept, deprecated aliases. A flag audit that assumes either outcome for the whole family will be wrong about several of them."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
