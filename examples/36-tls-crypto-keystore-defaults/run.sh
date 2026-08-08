#!/usr/bin/env bash
# 36 -- TLS/crypto posture tightened (cumulative, no single JEP).
#
# The doc's Symptom line bundles several sub-claims. This test verifies the one
# that's cleanly version-pinned and deterministic: default keystore type
# JKS -> PKCS12 (JDK 9). It also PRINTS (but does not assert on) the
# jdk.tls.disabledAlgorithms security property for both JDKs, because that list
# turned out NOT to be a clean "JDK 8 allows it, JDK 25 doesn't" story -- see
# the finding below and README.md.
#
# Finding from building this test: this sandbox's JDK 8 (a recent Temurin
# 8u502 patch) ALREADY disables TLSv1/TLSv1.1 by default -- security-relevant
# properties like this one get backported to old JDK 8 patches too, so "JDK 8
# allows weak TLS by default" depends on exactly which JDK 8 PATCH LEVEL you're
# running, not just the major version. A team on an old, unpatched JDK 8u would
# see a starker contrast than this test can show on a freshly-downloaded one.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

"$JDK8_HOME/bin/javac" -d out8 KeystoreType.java DisabledAlgorithms.java
"$JDK25_HOME/bin/javac" -d out25 KeystoreType.java DisabledAlgorithms.java 2>/dev/null

echo "Default keystore type:"
j8_ks="$("$JDK8_HOME/bin/java" -cp out8 KeystoreType 2>&1)"
j25_ks="$("$JDK25_HOME/bin/java" -cp out25 KeystoreType 2>&1)"
echo "  JDK 8:  $j8_ks"
echo "  JDK 25: $j25_ks"

echo "jdk.tls.disabledAlgorithms (informational only, not asserted on -- see README.md):"
echo "  JDK 8:  $("$JDK8_HOME/bin/java" -cp out8 DisabledAlgorithms 2>&1)"
echo "  JDK 25: $("$JDK25_HOME/bin/java" -cp out25 DisabledAlgorithms 2>&1)"

rm -rf out8 out25

if echo "$j8_ks" | grep -qi "= jks$" && echo "$j25_ks" | grep -qi "= pkcs12$"; then
  echo "REPRODUCED: default keystore type is JKS on JDK 8, PKCS12 on JDK 25 -- code creating a keystore with no explicit type gets a different on-disk format silently."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
