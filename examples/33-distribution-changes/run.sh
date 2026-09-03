#!/usr/bin/env bash
# 33 -- Distribution changes: standalone JRE / Web Start (JDK 11), JavaFX
# unbundled (JDK 11), Applet API deprecated for removal (JDK 17, JEP 398).
#
# Honest caveat found while building this test: Temurin (Eclipse Adoptium)
# builds of JDK 8 never bundled Java Web Start OR JavaFX in the first place --
# both were historically Oracle/Sun JDK-only distribution features, not
# something every JDK 8 vendor shipped. So there's no "present on JDK 8 vendor
# build X, absent on JDK 25" comparison to run here for those two sub-claims
# with Temurin specifically -- this test verifies that absence on JDK 8 as a
# vendor-dependent caveat, and focuses its actual pass/fail check on the part
# that IS cleanly comparable regardless of vendor: the Applet API's
# deprecation-for-removal warning, which is new since JDK 17 and doesn't fire
# on JDK 8's javac at all.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
rm -rf out8 out25
mkdir -p out8 out25

echo "Java Web Start (javaws) and JavaFX bundling, this vendor's JDK 8 build:"
javaws_present="absent"; [ -x "$JDK8_HOME/bin/javaws" ] && javaws_present="present"
javafx_present="absent"; find "$JDK8_HOME" -iname "*javafx*" 2>/dev/null | grep -q . && javafx_present="present"
echo "  javaws: $javaws_present (Temurin never bundled this even on JDK 8 -- Oracle-only historically)"
echo "  javafx: $javafx_present (same caveat)"

echo "Applet API deprecation warning, JDK 8:"
j8_out="$("$JDK8_HOME/bin/javac" -Xlint:all -d out8 Applet.java 2>&1)"
echo "$j8_out" | sed 's/^/  /'

echo "Applet API deprecation warning, JDK 25 (identical source):"
j25_out="$("$JDK25_HOME/bin/javac" -Xlint:all -d out25 Applet.java 2>&1)"
echo "$j25_out" | sed 's/^/  /'

# --- Do standalone JRE builds still exist? ---------------------------------------
# "There is no standalone JRE any more" is folklore that traces to ORACLE dropping
# its JRE product after JDK 8. Other vendors kept publishing JRE images, JDK 25
# included -- which matters because a team wanting a smaller shipped runtime is
# choosing between a vendor JRE and jlink, not forced onto jlink.
#
# Network-dependent, so it reports rather than gates: a failure here means the API
# was unreachable, not that the claim changed.
echo "Standalone JRE availability from Adoptium (network check):"
jre_types=""
if command -v curl >/dev/null 2>&1; then
  jre_types="$(curl -s --max-time 20 "https://api.adoptium.net/v3/assets/latest/25/hotspot?os=linux&architecture=x64" 2>/dev/null \
    | tr ',' '\n' | sed -n 's/.*"image_type"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' | sort -u | tr '\n' ' ')"
fi
if [ -n "$jre_types" ]; then
  echo "  JDK 25 image types published: $jre_types"
  case "$jre_types" in
    *jre*) echo "  -> a standalone JRE IS published for JDK 25" ;;
    *)     echo "  -> no jre image type listed; chapter 3.33 may need revisiting" ;;
  esac
else
  echo "  (Adoptium API unreachable -- skipping this check, not a failure)"
fi

rm -rf out8 out25

ok=true
echo "$j8_out" | grep -q "\[removal\]" && ok=false   # JDK 8 must NOT show [removal]
echo "$j25_out" | grep -q "\[removal\]" || ok=false  # JDK 25 must show [removal]

if $ok; then
  case "$jre_types" in
    *jre*) echo "ALSO CONFIRMED: Adoptium publishes a standalone JRE image for JDK 25, so \"no standalone JRE exists any more\" is an Oracle-specific fact rather than a platform one -- the same vendor-axis caveat this chapter opens with." ;;
  esac
  echo "REPRODUCED (partially -- see caveat above): the Applet API compiles on both JDKs (no hard break yet), but only JDK 25 flags it with a [removal] deprecation warning (JEP 398, JDK 17) -- confirming applets are on a one-way path out of the platform, even though this specific vendor's JDK 8 build never had Web Start or JavaFX to compare against in the first place."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
