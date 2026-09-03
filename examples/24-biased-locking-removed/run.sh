#!/usr/bin/env bash
# 24 -- Biased locking disabled and removed (JEP 374, disabled by default JDK 15).
#
# "No error, just a throughput regression" is the usual summary of this item, and
# it's true for code that DOESN'T explicitly pass -XX:+UseBiasedLocking. But a
# surprising number of perf-tuned production JVM configs from the JDK 8 era carry
# that flag explicitly (it was a common tuning recommendation for lock-heavy
# workloads for years) -- and this test found that explicitly SETTING the flag is
# actually a Won't-Start failure on JDK 25, not a silent regression at all.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out
mkdir -p out
"$JDK8_HOME/bin/javac" -d out Bias.java

echo "JDK 8, default (no explicit biased-locking flag):"
j8_out="$("$JDK8_HOME/bin/java" -cp out Bias 2>&1)"; j8_exit=$?
echo "$j8_out" | sed 's/^/  /'
echo "  exit=$j8_exit"

echo "JDK 8, with -XX:+UseBiasedLocking explicitly (a common JDK-8-era tuning flag):"
j8bias_out="$("$JDK8_HOME/bin/java" -XX:+UseBiasedLocking -cp out Bias 2>&1)"; j8bias_exit=$?
echo "$j8bias_out" | sed 's/^/  /'
echo "  exit=$j8bias_exit"

echo "JDK 25, default (no explicit biased-locking flag):"
j25_out="$("$JDK25_HOME/bin/java" -cp out Bias 2>&1)"; j25_exit=$?
echo "$j25_out" | sed 's/^/  /'
echo "  exit=$j25_exit"

echo "JDK 25, with the SAME explicit -XX:+UseBiasedLocking flag carried forward from the JDK 8 config:"
j25bias_out="$("$JDK25_HOME/bin/java" -XX:+UseBiasedLocking -cp out Bias 2>&1)"; j25bias_exit=$?
echo "$j25bias_out" | sed 's/^/  /'
echo "  exit=$j25bias_exit"

rm -rf out

ok=true
[ "$j8_exit" -eq 0 ] || ok=false
[ "$j8bias_exit" -eq 0 ] || ok=false
[ "$j25_exit" -eq 0 ] || ok=false
[ "$j25bias_exit" -ne 0 ] || ok=false
echo "$j25bias_out" | grep -q "Unrecognized VM option" || ok=false

if $ok; then
  echo "REPRODUCED, and it lands in two different categories depending on the config: without the explicit flag, JDK 25 just runs (silent throughput-only difference, not tested here -- see README.md). WITH the flag explicitly carried forward from a JDK-8-era tuned config, JDK 25 refuses to start at all -- Won't Start, not Runs But Wrong, for anyone who set this flag on purpose."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
