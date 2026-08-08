#!/usr/bin/env bash
# 04 -- Extension and endorsed-standards mechanisms removed (JEP 220).
#
# -Djava.ext.dirs and -Djava.endorsed.dirs were long-deprecated no-ops-with-a-warning
# on JDK 8. On JDK 9+ (modular run-time images) the launcher rejects them outright:
# the VM refuses to start.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"

echo "JDK 8 with -Djava.ext.dirs=/tmp -version:"
j8e_out="$("$JDK8_HOME/bin/java" -Djava.ext.dirs=/tmp -version 2>&1)"; j8e_exit=$?
echo "$j8e_out" | sed 's/^/  /'; echo "  exit=$j8e_exit"

echo "JDK 25 with -Djava.ext.dirs=/tmp -version:"
j25e_out="$("$JDK25_HOME/bin/java" -Djava.ext.dirs=/tmp -version 2>&1)"; j25e_exit=$?
echo "$j25e_out" | sed 's/^/  /'; echo "  exit=$j25e_exit"

echo "JDK 8 with -Djava.endorsed.dirs=/tmp -version:"
j8d_out="$("$JDK8_HOME/bin/java" -Djava.endorsed.dirs=/tmp -version 2>&1)"; j8d_exit=$?
echo "$j8d_out" | sed 's/^/  /'; echo "  exit=$j8d_exit"

echo "JDK 25 with -Djava.endorsed.dirs=/tmp -version:"
j25d_out="$("$JDK25_HOME/bin/java" -Djava.endorsed.dirs=/tmp -version 2>&1)"; j25d_exit=$?
echo "$j25d_out" | sed 's/^/  /'; echo "  exit=$j25d_exit"

ok=true
[ "$j8e_exit" -eq 0 ] || ok=false
[ "$j8d_exit" -eq 0 ] || ok=false
[ "$j25e_exit" -ne 0 ] || ok=false
[ "$j25d_exit" -ne 0 ] || ok=false
echo "$j25e_out" | grep -qi "is not supported" || ok=false
echo "$j25d_out" | grep -qi "is not supported" || ok=false

if $ok; then
  echo "REPRODUCED: both flags are silently-tolerated no-ops on JDK 8 but refuse VM startup entirely on JDK 25."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
