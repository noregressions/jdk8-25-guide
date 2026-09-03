#!/usr/bin/env bash
# 14 -- sun.misc.Unsafe memory-access methods (JEP 471 deprecation, JEP 498 warnings).
#
# Three checks: JDK 8 (silent), JDK 25 default (a one-time runtime warning, still
# works), and JDK 25 with --sun-misc-unsafe-memory-access=deny -- which simulates
# the FUTURE default this JEP is heading toward, turning the warning into a real
# UnsupportedOperationException today, on demand, without waiting for that future
# release to actually ship.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 UnsafeTest.java 2>/dev/null
echo "JDK 8:"
j8_out="$("$JDK8_HOME/bin/java" -cp out8 UnsafeTest 2>&1)"; j8_exit=$?
echo "$j8_out" | sed 's/^/  /'
echo "  exit=$j8_exit"

"$JDK25_HOME/bin/javac" -d out25 UnsafeTest.java 2>/dev/null
echo "JDK 25 (default):"
j25_out="$("$JDK25_HOME/bin/java" -cp out25 UnsafeTest 2>&1)"; j25_exit=$?
echo "$j25_out" | sed 's/^/  /'
echo "  exit=$j25_exit"

echo "JDK 25 with --sun-misc-unsafe-memory-access=deny (simulating the future default):"
j25deny_out="$("$JDK25_HOME/bin/java" --sun-misc-unsafe-memory-access=deny -cp out25 UnsafeTest 2>&1)"; j25deny_exit=$?
echo "$j25deny_out" | sed 's/^/  /'
echo "  exit=$j25deny_exit"

# --- How much does the default warning actually tell you? ----------------------
# How coarse is the default warn mode? UnsafeGranularity has three distinct putInt
# call sites across two classes, plus an objectFieldOffset call in a third. If the
# warning were per call site -- the natural assumption -- that would be four
# warnings. What actually happens is one warning for the entire JVM run, naming
# only whichever memory-access method ran first, so the count of warnings in a log
# says essentially nothing about how much Unsafe is left to remove.
"$JDK25_HOME/bin/javac" -nowarn -d out25 UnsafeGranularity.java 2>/dev/null
echo "JDK 25 default (warn) -- 4 Unsafe call sites across 3 classes:"
gran_warn="$("$JDK25_HOME/bin/java" -cp out25 UnsafeGranularity 2>&1)"
echo "$gran_warn" | sed 's/^/  /'
warn_blocks=$(echo "$gran_warn" | grep -c "^WARNING: A terminally deprecated" || true)

echo "JDK 25 with --sun-misc-unsafe-memory-access=debug -- same 4 call sites:"
gran_debug="$("$JDK25_HOME/bin/java" --sun-misc-unsafe-memory-access=debug -cp out25 UnsafeGranularity 2>&1)"
echo "$gran_debug" | grep -E "called by|\tat UnsafeGranularity" | sed 's/^/  /'
debug_sites=$(echo "$gran_debug" | grep -c "^WARNING: sun.misc.Unsafe::.* called by" || true)

echo ""
echo "warning blocks under the default (warn) ....... $warn_blocks"
echo "call sites located under =debug ............... $debug_sites"

# --- How much of the class is on the removal path? -------------------------------
# The "79 memory-access methods" figure from JEP 471 is widely quoted as if it were
# the whole class. Counted on the JDK in front of us instead, because the totals move.
"$JDK25_HOME/bin/javac" -nowarn -d out25 UnsafeSurface.java 2>/dev/null
echo "sun.misc.Unsafe surface on JDK 25:"
surface="$("$JDK25_HOME/bin/java" -cp out25 UnsafeSurface 2>&1 | grep -v WARNING)"
echo "$surface" | sed 's/^/  /'
s_pub=$(echo "$surface" | sed -n 's/.*public=\([0-9]*\).*/\1/p')
s_rem=$(echo "$surface" | sed -n 's/.*forRemoval=\([0-9]*\).*/\1/p')
s_surv=$(echo "$surface" | sed -n 's/.*surviving=\([0-9]*\).*/\1/p')

rm -rf out8 out25

ok=true
[ "$j8_exit" -eq 0 ] || ok=false
echo "$j8_out" | grep -q "^h.x via Unsafe = 42" || ok=false
[ "$j25_exit" -eq 0 ] || ok=false
echo "$j25_out" | grep -qi "WARNING.*terminally deprecated" || ok=false
[ "$j25deny_exit" -ne 0 ] || ok=false
echo "$j25deny_out" | grep -q "UnsupportedOperationException" || ok=false
[ "$warn_blocks" -eq 1 ] || ok=false
[ "$debug_sites" -eq 4 ] || ok=false
# Nearly the whole class is annotated, and only a handful survive. Asserted as a
# range rather than an exact figure, because these totals move between releases --
# the point is the proportion, not a specific number.
[ "${s_pub:-0}" -ge 80 ] || { echo "MISMATCH: expected >=80 public methods, got ${s_pub:-?}"; ok=false; }
[ "${s_rem:-0}" -ge 79 ] || { echo "MISMATCH: expected >=79 forRemoval methods, got ${s_rem:-?}"; ok=false; }
[ "${s_surv:-99}" -le 5 ] || { echo "MISMATCH: expected <=5 surviving methods, got ${s_surv:-?}"; ok=false; }

if $ok; then
  echo "REPRODUCED: Unsafe memory access is silent on JDK 8, warns-but-works by default on JDK 25, and --sun-misc-unsafe-memory-access=deny turns that warning into a real UnsupportedOperationException today -- a live preview of the eventual future default."
  echo "ALSO REPRODUCED: this is very nearly the whole class, not a corner of it. On this JDK $s_rem of $s_pub public methods on sun.misc.Unsafe carry @Deprecated(forRemoval=true), leaving $s_surv survivors -- so JEP 471's oft-quoted \"79 memory-access methods\" understates the annotated surface, though it remains the exact set the --sun-misc-unsafe-memory-access flag governs."
  echo "ALSO REPRODUCED: the default warn mode is far coarser than per-call-site. Four Unsafe call sites across three classes produced $warn_blocks warning block for the whole JVM run, naming only the method that happened to run first; the three putInt sites were never mentioned. =debug located all $debug_sites with file and line. The warning count in a log is not a measure of how much Unsafe a codebase uses -- only =debug gives you the inventory."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
