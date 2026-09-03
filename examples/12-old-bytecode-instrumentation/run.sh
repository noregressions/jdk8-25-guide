#!/usr/bin/env bash
# 12 -- Old bytecode instrumentation libraries (class file major version bump).
#
# Every JDK release increments the class file major version (JDK 8 = 52, JDK 25 =
# 69). Old ASM/ByteBuddy/CGLIB-based instrumentation, proxying, or mocking
# libraries that hard-code a max-supported major version reject anything newer --
# this test demonstrates the underlying mechanism directly: compile with JDK 25,
# then try to load that class file with JDK 8's JVM (which is exactly what an
# unpatched old library's own bytecode reader does internally when asked to parse
# a class file it's never seen the major version number for).
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 Simple.java
"$JDK25_HOME/bin/javac" -d out25 Simple.java

v8=$("$JDK25_HOME/bin/javap" -v out8/Simple.class 2>&1 | grep "major version" | awk '{print $3}')
v25=$("$JDK25_HOME/bin/javap" -v out25/Simple.class 2>&1 | grep "major version" | awk '{print $3}')
echo "JDK 8  compiled class file major version: $v8"
echo "JDK 25 compiled class file major version: $v25"

echo "Loading the JDK-25-compiled class file with JDK 8's JVM:"
load_out="$("$JDK8_HOME/bin/java" -cp out25 Simple 2>&1)"; load_exit=$?
echo "$load_out" | sed 's/^/  /'
echo "  exit=$load_exit"

rm -rf out8 out25

# --- The --release 8 bridge the chapter offers ------------------------------------
# Chapter 3.12 notes that compiling with `javac --release 8` on JDK 25 emits
# version-52 class files, which an old bytecode reader can still parse -- a way to
# keep a stuck instrumentation tool alive through a transition. Pinned here because
# it is a concrete recommendation a reader will act on.
echo ""
echo "javac --release 8 on JDK 25 -- what class-file version comes out?"
rel_dir="$(mktemp -d)"
printf 'public class RelProbe { public static void main(String[] a){} }\n' > "$rel_dir/RelProbe.java"
"$JDK25_HOME/bin/javac" --release 8 -nowarn -d "$rel_dir" "$rel_dir/RelProbe.java" 2>/dev/null
rel_major=$("$JDK25_HOME/bin/javap" -v -cp "$rel_dir" RelProbe 2>/dev/null | sed -n 's/.*major version: \([0-9]*\).*/\1/p')
echo "  major version: ${rel_major:-unknown}  (plain javac on JDK 25 emits 69)"
rm -rf "$rel_dir"

if [ "${rel_major:-0}" != "52" ]; then
  echo "MISMATCH: javac --release 8 on JDK 25 emitted major version ${rel_major:-unknown}, expected 52"
  exit 1
fi

if [ "$v8" = "52" ] && [ "$v25" = "69" ] && [ "$load_exit" -ne 0 ] && \
   echo "$load_out" | grep -q "UnsupportedClassVersionError"; then
  echo "REPRODUCED: class file major version jumped 52 -> 69 across JDK 8 -> 25; an older JVM (or an old instrumentation library's internal class-file parser) rejects the newer format outright."
  echo "ALSO CONFIRMED: javac --release 8 on JDK 25 emits major version $rel_major, so the bridge the chapter describes works -- an old bytecode reader can still parse the output. It costs you every language feature since 8, which is why it is a bridge and not a destination."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
