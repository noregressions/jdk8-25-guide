#!/usr/bin/env bash
# 06 -- Removed Java EE packages (JEP 320).
#
# javax.xml.bind (JAXB) was bundled in the JDK 8 runtime. Compile+run on JDK 8,
# then run the SAME class file (no recompile) on JDK 25 -- it's not on the
# classpath anymore because the JDK itself no longer ships it.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -f EE.class
mkdir -p out
"$JDK8_HOME/bin/javac" -d out EE.java

echo "JDK 8:"
j8_out="$("$JDK8_HOME/bin/java" -cp out EE 2>&1)"; j8_exit=$?
echo "$j8_out" | sed 's/^/  /'
echo "  exit=$j8_exit"

echo "JDK 25 (same .class file, no recompile):"
j25_out="$("$JDK25_HOME/bin/java" -cp out EE 2>&1)"; j25_exit=$?
echo "$j25_out" | sed 's/^/  /'
echo "  exit=$j25_exit"

# --- Which tool actually finds this? ---------------------------------------------
# Worth pinning, because the obvious choice is the wrong one. `jdeps --jdk-internals`
# reports NOTHING here and exits 0 -- these were removed *public* APIs, not
# encapsulated internals, so a clean internals report is silence rather than
# reassurance. And `jdeprscan` cannot help on the target JDK either: it needs to
# resolve the classes to know they were deprecated, and on JDK 25 they are gone, so
# it reports no findings at all and exits 0 -- a clean bill of health for a class that
# crashes at class-load time.
#
# Plain `jdeps` -- no flags -- is the detector that works on the target JDK: it
# reports the missing packages as "not found". One command, no old JDK required.
echo "jdeps --jdk-internals on JDK 25 (the obvious choice):"
internals="$("$JDK25_HOME/bin/jdeps" --jdk-internals out 2>&1)"; internals_exit=$?
if [ -z "$internals" ]; then echo "  (no output at all -- exit=$internals_exit)"
else echo "$internals" | sed 's/^/  /'; fi

echo "jdeps with no flags on JDK 25 (the one that finds it):"
plain="$("$JDK25_HOME/bin/jdeps" out 2>&1)"
echo "$plain" | grep -E "not found" | sed 's/^/  /'

echo "jdeprscan --for-removal on JDK 25:"
scan="$("$JDK25_HOME/bin/jdeprscan" --for-removal out 2>&1)"; scan_exit=$?
echo "$scan" | sed 's/^/  /'
scan_findings=$(echo "$scan" | grep -c "uses deprecated\|overrides deprecated" || true)
echo "  (findings reported: $scan_findings, exit=$scan_exit)"

rm -rf out

if [ "$j8_exit" -eq 0 ] && [ "$j25_exit" -ne 0 ] && echo "$j25_out" | grep -q "NoClassDefFoundError"; then
  extra_ok=1
  [ -z "$internals" ] || { echo "MISMATCH: jdeps --jdk-internals unexpectedly reported something"; extra_ok=0; }
  echo "$plain" | grep -qE "javax\.xml\.bind.*not found" || { echo "MISMATCH: plain jdeps should report javax.xml.bind as not found"; extra_ok=0; }
  [ "$scan_findings" -eq 0 ] && [ "$scan_exit" -eq 0 ] || { echo "MISMATCH: jdeprscan on JDK 25 was expected to report nothing and exit 0"; extra_ok=0; }
  echo "REPRODUCED: javax.xml.bind classes run fine on JDK 8, but NoClassDefFoundError on JDK 25 -- the JDK no longer ships them."
  if [ "$extra_ok" = "1" ]; then
    echo "ALSO REPRODUCED: the detector matters. jdeps --jdk-internals prints nothing and exits 0 -- these are removed PUBLIC APIs, not encapsulated internals, so a clean internals report is silence, not safety. jdeprscan is no better on JDK 25: it reports zero findings and exits 0, because the classes it would flag are no longer there to flag -- a clean bill of health for code that crashes at class-load time. Plain jdeps, with no flags, is the one that works on the target JDK -- it lists the packages as \"not found\"."
    exit 0
  fi
  echo "DID NOT REPRODUCE the detector behaviour -- investigate."
  exit 1
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
