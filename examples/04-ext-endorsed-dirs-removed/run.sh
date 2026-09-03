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

# --- The Xbootclasspath controls -------------------------------------------------
# Any grep that finds ext.dirs/endorsed.dirs also finds Xbootclasspath, and the two
# suffixes went opposite ways: /p: (prepend) is rejected on JDK 25 with its own
# message, while /a: (append) is still supported. So an audit hit on Xbootclasspath
# needs reading, not deleting -- which is the point of running both here.
echo "JDK 25 with -Xbootclasspath/a:/tmp -version (append -- expected to survive):"
j25a_out="$("$JDK25_HOME/bin/java" -Xbootclasspath/a:/tmp -version 2>&1)"; j25a_exit=$?
echo "$j25a_out" | head -1 | sed 's/^/  /'; echo "  exit=$j25a_exit"

echo "JDK 25 with -Xbootclasspath/p:/tmp -version (prepend -- expected to fail):"
j25p_out="$("$JDK25_HOME/bin/java" -Xbootclasspath/p:/tmp -version 2>&1)"; j25p_exit=$?
echo "$j25p_out" | head -1 | sed 's/^/  /'; echo "  exit=$j25p_exit"

ok=true
[ "$j8e_exit" -eq 0 ] || ok=false
[ "$j8d_exit" -eq 0 ] || ok=false
[ "$j25e_exit" -ne 0 ] || ok=false
[ "$j25d_exit" -ne 0 ] || ok=false
echo "$j25e_out" | grep -qi "is not supported" || ok=false
echo "$j25d_out" | grep -qi "is not supported" || ok=false
[ "$j25a_exit" -eq 0 ] || { echo "MISMATCH: -Xbootclasspath/a: should still be supported on JDK 25"; ok=false; }
[ "$j25p_exit" -ne 0 ] || { echo "MISMATCH: -Xbootclasspath/p: should be rejected on JDK 25"; ok=false; }
echo "$j25p_out" | grep -qi "no longer a supported option" || { echo "MISMATCH: unexpected /p: message"; ok=false; }

if $ok; then
  echo "REPRODUCED: both flags are silently-tolerated no-ops on JDK 8 but refuse VM startup entirely on JDK 25."
  echo "ALSO REPRODUCED: the Xbootclasspath suffixes diverge. -Xbootclasspath/a: (append) still works on JDK 25; -Xbootclasspath/p: (prepend) is rejected with \"no longer a supported option\". A grep for Xbootclasspath therefore needs reading rather than deleting on sight."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
