#!/usr/bin/env bash
# T01 -- jdeps --jdk-internals: the module annotation is the whole finding.
#
# "JDK internal API" is not one category, and the package prefix does not tell you
# which one you are in. This pins the three-way split behind chapter 1.1:
#
#   sun.misc.Unsafe                -> (jdk.unsupported) -- escape hatch, warns, runs
#   sun.reflect.ReflectionFactory  -> (jdk.unsupported) -- escape hatch, silent, runs
#   sun.security.x509.X509CertImpl -> (java.base)       -- encapsulated, throws
#
# Both jdk.unsupported entries start with "sun." and both still run on JDK 25 with
# no flags at all; only the java.base one fails. So the module in the last column
# is the triage signal, not the package name.
#
# It also pins the failure MODE, which decides which flag you reach for. A jdeps
# finding is a *declared* bytecode dependency, so an encapsulated one fails at link
# time with IllegalAccessError and is opened with --add-exports.
# InaccessibleObjectException is a different failure: it comes from
# setAccessible(), needs --add-opens, and belongs to the reflective path jdeps
# cannot see at all.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out; mkdir -p out

# Compile under JDK 8, where all three are ordinary compilable API.
"$JDK8_HOME/bin/javac" -nowarn -d out Probe.java 2>/dev/null

echo "jdeps --jdk-internals (JDK 25) on the javac8-compiled class:"
scan="$("$JDK25_HOME/bin/jdeps" --jdk-internals out 2>&1)"
echo "$scan" | grep -E '^\s+Probe\s+->' | sed 's/^/  /'

mod_of() { echo "$scan" | grep -m1 "\-> $1 " | sed -n 's/.*JDK internal API (\([a-z.]*\)).*/\1/p'; }
m_unsafe=$(mod_of "sun.misc.Unsafe")
m_rf=$(mod_of "sun.reflect.ReflectionFactory")
m_x509=$(mod_of "sun.security.x509.X509CertImpl")

echo ""
echo "jdeps module annotations:"
echo "  sun.misc.Unsafe                -> $m_unsafe"
echo "  sun.reflect.ReflectionFactory  -> $m_rf"
echo "  sun.security.x509.X509CertImpl -> $m_x509"

echo ""
echo "Same class file, RUN unmodified on JDK 25 with no --add-opens/--add-exports:"
run_out="$("$JDK25_HOME/bin/java" -cp out Probe 2>&1)"
echo "$run_out" | sed 's/^/  /'
rf_result=$(echo "$run_out"  | sed -n 's/^ReflectionFactory: \(.*\)$/\1/p')
x509_result=$(echo "$run_out" | sed -n 's/^X509CertImpl: \(.*\)$/\1/p')

rm -rf out

ok=1
[ "$m_rf"    = "jdk.unsupported" ] || { echo "MISMATCH: ReflectionFactory annotated '$m_rf', expected jdk.unsupported"; ok=0; }
[ "$m_unsafe" = "jdk.unsupported" ] || { echo "MISMATCH: Unsafe annotated '$m_unsafe', expected jdk.unsupported"; ok=0; }
[ "$m_x509"  = "java.base" ]       || { echo "MISMATCH: X509CertImpl annotated '$m_x509', expected java.base"; ok=0; }
case "$rf_result"   in OK*) ;; *) echo "MISMATCH: ReflectionFactory call did not succeed (got '$rf_result')"; ok=0;; esac
[ "$x509_result" = "java.lang.IllegalAccessError" ] || { echo "MISMATCH: X509CertImpl gave '$x509_result', expected java.lang.IllegalAccessError"; ok=0; }

echo ""
if [ "$ok" = "1" ]; then
  echo "REPRODUCED: jdeps sorts JDK-internal findings by MODULE, and the module is the triage signal. sun.misc.Unsafe and sun.reflect.ReflectionFactory both sit in jdk.unsupported and both still run on JDK 25 with no flags -- ReflectionFactory without even a warning. Only the java.base finding is genuinely encapsulated, and it fails with IllegalAccessError at link time (not InaccessibleObjectException) because a jdeps finding is a declared dependency, which makes --add-exports the relevant flag rather than --add-opens."
  exit 0
else
  echo "DID NOT REPRODUCE the documented behaviour -- investigate."
  exit 1
fi
