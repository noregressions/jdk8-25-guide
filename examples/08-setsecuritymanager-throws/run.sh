#!/usr/bin/env bash
# 08 -- System.setSecurityManager() (JEP 411 groundwork / JEP 486 unconditional).
#
# Three checks: JDK 8 (works), JDK 25 default (UnsupportedOperationException from
# the call site itself -- distinct from test 02's VM-init-time failure), and JDK 25
# with -Djava.security.manager=allow (the JDK 18-23 opt-out flag) to confirm it no
# longer works at all on 25 -- it now fails even earlier, at VM init, same as test 02.
#
# Caveat: only JDK 8 and JDK 25 are installed here, so the JDK 18-23 window in which
# =allow genuinely works as an opt-out can't be verified directly -- only that by
# JDK 25 that window has definitely closed.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 SetSM.java
echo "JDK 8:"
j8_out="$("$JDK8_HOME/bin/java" -cp out8 SetSM 2>&1)"; j8_exit=$?
echo "$j8_out" | sed 's/^/  /'
echo "  exit=$j8_exit"

"$JDK25_HOME/bin/javac" -d out25 SetSM.java 2>/dev/null
echo "JDK 25 (default):"
j25_out="$("$JDK25_HOME/bin/java" -cp out25 SetSM 2>&1)"; j25_exit=$?
echo "$j25_out" | sed 's/^/  /'
echo "  exit=$j25_exit"

echo "JDK 25 with -Djava.security.manager=allow (the JDK 18-23 opt-out flag):"
j25allow_out="$("$JDK25_HOME/bin/java" -Djava.security.manager=allow -cp out25 SetSM 2>&1)"; j25allow_exit=$?
echo "$j25allow_out" | sed 's/^/  /'
echo "  exit=$j25allow_exit"

rm -rf out8 out25

ok=true
[ "$j8_exit" -eq 0 ] || ok=false
[ "$j25_exit" -ne 0 ] || ok=false
echo "$j25_out" | grep -q "UnsupportedOperationException" || ok=false
[ "$j25allow_exit" -ne 0 ] || ok=false
echo "$j25allow_out" | grep -q "initialization of VM" || ok=false

if $ok; then
  echo "REPRODUCED: setSecurityManager() works on JDK 8; throws UnsupportedOperationException by default on JDK 25; and the JDK 18-23 =allow opt-out flag no longer works either -- it now fails even earlier, at VM init."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
