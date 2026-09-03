#!/usr/bin/env bash
# 20 -- Compact object headers (JEP 519): what the shipped default actually is.
#
# JDK-25-only check -- UseCompactObjectHeaders doesn't exist as a flag on JDK 8 at
# all (the option itself is new in 25), so there's no JDK 8 side to compare. What
# this test verifies is narrower but load-bearing: what the shipped DEFAULT
# actually is, since the whole risk profile of this item depends on it.
set -uo pipefail
: "${JDK25_HOME:?set JDK25_HOME}"

flag_line="$("$JDK25_HOME/bin/java" -XX:+PrintFlagsFinal -version 2>&1 | grep 'UseCompactObjectHeaders ')"
echo "JDK 25 -XX:+PrintFlagsFinal | grep UseCompactObjectHeaders:"
echo "  $flag_line"

default_value=$(echo "$flag_line" | awk '{print $4}')
echo "shipped default value: $default_value"

if [ "$default_value" = "false" ]; then
  echo "REPRODUCED: UseCompactObjectHeaders defaults to false (OFF) on JDK 25 -- read from the shipped flag table rather than asserted. That default is what makes this a day-TWO risk, triggered by someone enabling the flag, rather than something that bites on first boot."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate. (got default=$default_value)"
  exit 1
fi
