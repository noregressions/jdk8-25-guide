#!/usr/bin/env bash
# 21 -- ThreadGroup degradation (spans JDK 14-20, no single JEP).
#
# Two checks, because the two methods this item bundles together degrade in
# DIFFERENT ways -- a nuance the reference doc's single "throw since JDK 20"
# sentence glosses over:
#   - stop(): compiled under JDK 8, run (not recompiled) against JDK 25 -> throws
#     NoSuchMethodError. This is NOT "throws UnsupportedOperationException like
#     Thread.stop() does" (test 10) -- it's gone from the class entirely, a harder
#     break than the doc's wording implies.
#   - destroy(): still callable on JDK 25, but silently a no-op -- exactly as
#     documented.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 TGStop.java TGDestroy.java 2>&1

echo "-- ThreadGroup.stop(), JDK-8-compiled class, run on JDK 8: --"
stop8_out="$("$JDK8_HOME/bin/java" -cp out8 TGStop 2>&1)"
echo "$stop8_out" | sed 's/^/  /'

echo "-- ThreadGroup.stop(), SAME JDK-8-compiled class, run on JDK 25 (no recompile): --"
stop25_out="$("$JDK25_HOME/bin/java" -cp out8 TGStop 2>&1)"
echo "$stop25_out" | sed 's/^/  /'

echo "-- ThreadGroup.destroy(), JDK 8: --"
"$JDK25_HOME/bin/javac" -d out25 TGDestroy.java 2>/dev/null
destroy8_out="$("$JDK8_HOME/bin/java" -cp out8 TGDestroy 2>&1)"
echo "$destroy8_out" | sed 's/^/  /'

echo "-- ThreadGroup.destroy(), JDK 25: --"
destroy25_out="$("$JDK25_HOME/bin/java" -cp out25 TGDestroy 2>&1)"
echo "$destroy25_out" | sed 's/^/  /'

rm -rf out8 out25

ok=true
echo "$stop8_out" | grep -q "returned normally" || ok=false
echo "$stop25_out" | grep -q "NoSuchMethodError" || ok=false
echo "$destroy8_out" | grep -q "isDestroyed() after = true" || ok=false
echo "$destroy25_out" | grep -q "isDestroyed() after = false" || ok=false

if $ok; then
  echo "REPRODUCED: ThreadGroup.stop() works on JDK 8 but throws NoSuchMethodError on JDK 25 against old bytecode (harder than a simple 'throws' -- the method is gone from the class). ThreadGroup.destroy() is a silent, always-succeeds no-op on JDK 25 -- exactly as documented."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
