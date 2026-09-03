#!/usr/bin/env bash
# 26 -- Underscore as identifier: legal on javac8, a reserved keyword from javac9 onward.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -f Underscore.class

echo "Compile with javac 8:"
compile8_out="$("$JDK8_HOME/bin/javac" Underscore.java 2>&1)"; compile8_code=$?
echo "$compile8_out" | sed 's/^/  /'
echo "  exit=$compile8_code"

echo "Run the javac8-compiled binary on JDK 8:"
run8="$("$JDK8_HOME/bin/java" Underscore 2>&1)"
echo "$run8" | sed 's/^/  /'

echo "Run the SAME .class file on JDK 25 (old binary, new JVM):"
run25="$("$JDK25_HOME/bin/java" Underscore 2>&1)"
echo "$run25" | sed 's/^/  /'

rm -f Underscore.class

echo "Now recompile the SAME source with javac 25:"
compile25_out="$("$JDK25_HOME/bin/javac" Underscore.java 2>&1)"; compile25_code=$?
echo "$compile25_out" | sed 's/^/  /'
echo "  exit=$compile25_code"
rm -f Underscore.class

if [ "$compile8_code" -eq 0 ] && [ "$run8" = "value=42" ] && [ "$run25" = "value=42" ] \
   && [ "$compile25_code" -ne 0 ] && echo "$compile25_out" | grep -qi "underscore"; then
  echo "REPRODUCED: javac8 compiles it, the binary runs unchanged on JDK 25, but javac25 refuses to recompile the same source."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
