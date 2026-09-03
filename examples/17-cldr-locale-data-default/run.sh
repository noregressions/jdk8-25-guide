#!/usr/bin/env bash
# 17 -- CLDR locale data becomes the default provider (JEP 252).
#
# Formats a FULL-style date for ja_JP under both JDKs. The pass/fail check only
# looks at the numeric string length the program itself prints (an ASCII number),
# not at the actual Japanese text -- deliberately, so this test doesn't depend on
# the terminal/shell correctly displaying non-ASCII output. See README.md for what
# the actual formatted strings look like when captured with UTF-8 output encoding.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 Locale17.java
"$JDK25_HOME/bin/javac" -d out25 Locale17.java 2>/dev/null

echo "JDK 8 (COMPAT locale provider, the JDK 8 default):"
j8_out="$("$JDK8_HOME/bin/java" -Dfile.encoding=UTF-8 -cp out8 Locale17 2>&1)"
echo "$j8_out" | sed 's/^/  /'
j8_len=$(echo "$j8_out" | grep "length (chars)" | grep -o '[0-9]*$')

echo "JDK 25 (CLDR locale provider, the JDK 9+ default):"
j25_out="$("$JDK25_HOME/bin/java" -Dstdout.encoding=UTF-8 -cp out25 Locale17 2>&1)"
echo "$j25_out" | sed 's/^/  /'
j25_len=$(echo "$j25_out" | grep "length (chars)" | grep -o '[0-9]*$')

# --- The bridge flag, and its own separate timeline -------------------------------
# -Djava.locale.providers=COMPAT,CLDR is the stopgap most write-ups on JEP 252
# recommend. It was deprecated in JDK 21 and removed in JDK 23, so its behaviour
# depends on the target release: through 22 it still works (and warns), from 23 it
# is inert.
#
# Reported, NOT asserted. This test exists to find the JEP 252 boundary -- the
# release where CLDR became the default -- and gating on a JDK 23 behaviour would
# make the test fail on 9..22 for a reason that has nothing to do with JEP 252,
# destroying its value as a boundary probe. The release matrix caught exactly that
# mistake in an earlier version of this file.
echo "JDK 25 WITH -Djava.locale.providers=COMPAT,CLDR (the commonly recommended bridge):"
compat_out="$("$JDK25_HOME/bin/java" -Dstdout.encoding=UTF-8 -Djava.locale.providers=COMPAT,CLDR -cp out25 Locale17 2>&1)"
echo "$compat_out" | grep -v '^$' | sed 's/^/  /'
compat_len=$(echo "$compat_out" | grep "length (chars)" | grep -o '[0-9]*$')
compat_warned=$(echo "$compat_out" | grep -ci "COMPAT locale provider" || true)

rm -rf out8 out25

echo ""
echo "JDK 8  full-date string length:  $j8_len"
echo "JDK 25 full-date string length:  $j25_len"
echo "target + COMPAT,CLDR length:     $compat_len"
echo "JDK 25 logged a COMPAT locale provider notice: $compat_warned time(s)"

if [ -n "$j8_len" ] && [ -n "$j25_len" ] && [ "$j8_len" != "$j25_len" ]; then
  echo "REPRODUCED: the same locale + same date formats to a DIFFERENT length/content string under JDK 8's COMPAT provider vs JDK 25's CLDR provider -- no exception, no warning, just a silently different formatted value."
  if [ "$compat_len" = "$j25_len" ]; then
    echo "NOTE: -Djava.locale.providers=COMPAT,CLDR had NO effect on this target ($compat_len chars, same as no flag) -- consistent with the COMPAT provider having been removed in JDK 23. There is no bridge on this release; the structural fix is the only fix."
  else
    echo "NOTE: -Djava.locale.providers=COMPAT,CLDR still works on this target (it produced $compat_len chars vs $j25_len without it) -- consistent with a release before 23, where COMPAT was deprecated but not yet removed. Treating it as a bridge here buys time that ends at 23."
  fi
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
