#!/usr/bin/env bash
# 37 -- Container memory ergonomics changed (JDK 10, backported to 8u191).
#
# No Docker daemon is available in this sandbox (docker CLI is present, but
# `docker info` can't reach a daemon socket -- see ../NOTES.md). Rather than
# skip this item outright, this test uses a real cgroup v1 memory limit
# directly (no container runtime needed to exercise the same kernel mechanism
# a container would use) to check whether each JDK's heap ergonomics actually
# respect it.
#
# FINDING: this sandbox's JDK 8 build is 8u502 -- a current patch, well past
# the 8u191 backport point the reference doc itself names. Both JDK 8 and
# JDK 25 correctly compute MaxHeapSize from the cgroup limit in this test.
# That's an EXPECTED result given the doc's own wording, not a test failure --
# it confirms the backport claim, but it means this sandbox CANNOT reproduce
# the actual "before" state the doc's Symptom line describes (a pre-8u191
# image ignoring the container limit and sizing its heap off host RAM
# instead) -- that would need an actual pre-2018 JDK 8 binary, which isn't
# available through the current Adoptium API (see setup/download-jdks.sh --
# it only serves recent patches of each feature version).
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"

CGROUP=/sys/fs/cgroup/memory/discovery-test-37
if [ ! -d /sys/fs/cgroup/memory ]; then
  echo "SKIP: this environment has no cgroup v1 memory controller mounted -- cannot constrain a process's visible memory without one. If you have Docker available, the equivalent check is:"
  echo "  docker run --rm -m 512m -v \$JDK8_HOME:/jdk8 -v \$JDK25_HOME:/jdk25 debian:stable-slim /jdk8/bin/java -XX:+PrintFlagsFinal -version | grep MaxHeapSize"
  echo "  docker run --rm -m 512m -v \$JDK8_HOME:/jdk8 -v \$JDK25_HOME:/jdk25 debian:stable-slim /jdk25/bin/java -XX:+PrintFlagsFinal -version | grep MaxHeapSize"
  exit 2
fi

mkdir -p "$CGROUP" 2>/dev/null || {
  echo "SKIP: could not create a cgroup (needs root / cgroup delegation) -- see the Docker-based equivalent check in this script's header comment."
  exit 2
}
echo $((512*1024*1024)) > "$CGROUP/memory.limit_in_bytes" 2>/dev/null || {
  echo "SKIP: could not set a cgroup memory limit -- see the Docker-based equivalent check in this script's header comment."
  rmdir "$CGROUP" 2>/dev/null
  exit 2
}

run_constrained() {
  # NOTE: must use $$ from a genuinely NEW process (bash -c), not a plain ()
  # subshell -- bash defines $$ inside a () subshell as the PARENT shell's PID
  # for backward-compat reasons, so "echo $$ > cgroup.procs" inside a bare
  # subshell would move THIS SCRIPT's own process into the cgroup permanently,
  # silently constraining every later "unconstrained" check too. bash -c gets
  # a real, distinct PID.
  local jdk_home="$1" cgroup="$2"
  bash -c 'echo $$ > "$1/cgroup.procs" && exec "$2/bin/java" -XX:+PrintFlagsFinal -version' _ "$cgroup" "$jdk_home" 2>&1 | grep -i "MaxHeapSize "
}

echo "Host total memory:"
free -h | sed -n '1,2p' | sed 's/^/  /'

echo "JDK 8 ($JDK8_HOME) MaxHeapSize, unconstrained:"
"$JDK8_HOME/bin/java" -XX:+PrintFlagsFinal -version 2>&1 | grep -i "MaxHeapSize " | sed 's/^/  /'

echo "JDK 8 MaxHeapSize, constrained to a 512MB cgroup:"
j8_constrained="$(run_constrained "$JDK8_HOME" "$CGROUP")"
echo "$j8_constrained" | sed 's/^/  /'

echo "JDK 25 ($JDK25_HOME) MaxHeapSize, unconstrained:"
"$JDK25_HOME/bin/java" -XX:+PrintFlagsFinal -version 2>&1 | grep -i "MaxHeapSize " | sed 's/^/  /'

echo "JDK 25 MaxHeapSize, constrained to a 512MB cgroup:"
j25_constrained="$(run_constrained "$JDK25_HOME" "$CGROUP")"
echo "$j25_constrained" | sed 's/^/  /'

rmdir "$CGROUP" 2>/dev/null

j8_mb=$(echo "$j8_constrained" | grep -o '[0-9]\+' | head -1)
j25_mb=$(echo "$j25_constrained" | grep -o '[0-9]\+' | head -1)

if [ -n "$j8_mb" ] && [ -n "$j25_mb" ] && [ "$j8_mb" -lt 536870912 ] && [ "$j25_mb" -lt 536870912 ]; then
  echo
  echo "CONFIRMED (not a failure -- see header comment): both JDK 8 (8u502, well past the 8u191 backport) and JDK 25 correctly compute MaxHeapSize from the 512MB cgroup limit rather than host RAM. This sandbox cannot reproduce the actual pre-8u191 broken behaviour the doc's Symptom line describes -- that needs a genuinely old JDK 8 binary, not available here."
  exit 0
else
  echo "UNEXPECTED result -- neither JDK respected the cgroup limit as expected. Investigate."
  exit 1
fi
