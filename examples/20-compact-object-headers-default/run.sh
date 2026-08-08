#!/usr/bin/env bash
# 20 -- Compact object headers (JEP 519), and the deck's default-value error.
#
# JDK-25-only check -- UseCompactObjectHeaders doesn't exist as a flag on JDK 8 at
# all (the option itself is new in 25), so there's no JDK 8 side to compare. What
# this test verifies is narrower but load-bearing: what the shipped DEFAULT
# actually is, since the reference doc's correction says the deck got this wrong.
set -uo pipefail
: "${JDK25_HOME:?set JDK25_HOME}"

flag_line="$("$JDK25_HOME/bin/java" -XX:+PrintFlagsFinal -version 2>&1 | grep 'UseCompactObjectHeaders ')"
echo "JDK 25 -XX:+PrintFlagsFinal | grep UseCompactObjectHeaders:"
echo "  $flag_line"

default_value=$(echo "$flag_line" | awk '{print $4}')
echo "shipped default value: $default_value"

if [ "$default_value" = "false" ]; then
  echo "REPRODUCED: UseCompactObjectHeaders defaults to false (OFF) on JDK 25. The deck's PrintFlagsFinal slide shows it as 'true <- JDK 25 new', which the reference doc already flags as wrong -- this test confirms that correction against the real shipped default rather than just asserting it."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate. (got default=$default_value)"
  exit 1
fi
