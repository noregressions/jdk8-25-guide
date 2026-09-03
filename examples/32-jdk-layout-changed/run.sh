#!/usr/bin/env bash
# 32 -- JDK layout changed: rt.jar / tools.jar / jre/ removed in the module-image era.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"

check() {
  local home="$1" path="$2"
  if [ -e "$home/$path" ]; then echo "present"; else echo "absent"; fi
}

j8_jre="$(check "$JDK8_HOME" jre)"
j8_rtjar="$(check "$JDK8_HOME" jre/lib/rt.jar)"
j8_toolsjar="$(check "$JDK8_HOME" lib/tools.jar)"
j25_jre="$(check "$JDK25_HOME" jre)"
j25_rtjar="$(check "$JDK25_HOME" jre/lib/rt.jar)"
j25_toolsjar="$(check "$JDK25_HOME" lib/tools.jar)"

echo "JDK 8:  jre/=$j8_jre  jre/lib/rt.jar=$j8_rtjar  lib/tools.jar=$j8_toolsjar"
echo "JDK 25: jre/=$j25_jre  jre/lib/rt.jar=$j25_rtjar  lib/tools.jar=$j25_toolsjar"

if [ "$j8_jre" = present ] && [ "$j8_rtjar" = present ] && [ "$j8_toolsjar" = present ] \
   && [ "$j25_jre" = absent ] && [ "$j25_rtjar" = absent ] && [ "$j25_toolsjar" = absent ]; then
  echo "REPRODUCED: JDK 8 has the classic jre/rt.jar/tools.jar layout; JDK 25 has none of it."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
