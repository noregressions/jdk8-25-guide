#!/usr/bin/env bash
# 02 -- Security Manager startup flags (JEP 486).
#
# -Djava.security.manager on the command line used to just opt in to the (already
# deprecated-since-17) Security Manager. Since JDK 24 it is a VM-init-time fatal
# error: the VM refuses to start at all, before main() ever runs.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"

echo "JDK 8 with -Djava.security.manager -version:"
jdk8_out="$("$JDK8_HOME/bin/java" -Djava.security.manager -version 2>&1)"
jdk8_exit=$?
echo "$jdk8_out" | sed 's/^/  /'
echo "  exit=$jdk8_exit"

echo "JDK 25 with -Djava.security.manager -version:"
jdk25_out="$("$JDK25_HOME/bin/java" -Djava.security.manager -version 2>&1)"
jdk25_exit=$?
echo "$jdk25_out" | sed 's/^/  /'
echo "  exit=$jdk25_exit"

if [ "$jdk8_exit" -eq 0 ] && [ "$jdk25_exit" -ne 0 ] && echo "$jdk25_out" | grep -q "initialization of VM"; then
  echo "REPRODUCED: JDK 8 starts fine with -Djava.security.manager; JDK 25 refuses to start the VM at all."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
