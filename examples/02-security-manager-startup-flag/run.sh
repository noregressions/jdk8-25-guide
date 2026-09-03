#!/usr/bin/env bash
# 02 -- Security Manager startup flags (JEP 486).
#
# -Djava.security.manager on the command line used to just opt in to the (already
# deprecated-since-17) Security Manager. Since JDK 24 it is a VM-init-time fatal
# error: the VM refuses to start at all, before main() ever runs.
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"

echo "JDK 8 with -Djava.security.manager -version:"
jdk8_out="$("$JDK8_HOME/bin/java" -Djava.security.manager -version 2>&1)"
jdk8_exit=$?
echo "$jdk8_out" | sed 's/^/  /'
echo "  exit=$jdk8_exit"

echo "JDK 25 with -Djava.security.manager -version:"
jdk25_out="$("$JDK25_HOME/bin/java" -Djava.security.manager -version 2>&1)"
jdk25_exit=$?
echo "$jdk25_out" | sed 's/^/  /'
echo "  exit=$jdk25_exit"

# --- Which VALUES are fatal? -----------------------------------------------------
# "-Djava.security.manager is startup-fatal on 24+" is the easy summary and it is too
# broad. The error the VM prints is specific: it objects to a command line option
# that "has attempted to allow or enable" the Security Manager. `disallow` attempts
# neither -- it asks for the JDK 24 default -- so it is accepted and the VM starts.
#
# The distinction is practical. A config carrying =disallow explicitly, as
# belt-and-braces, is fine and does not need touching; every other spelling is fatal.
echo ""
echo "JDK 25, each value of -Djava.security.manager:"
declare -a fatal_values=() ok_values=()
for v in "" "=allow" "=disallow" "=default" "=mypkg.CustomSM"; do
  out="$("$JDK25_HOME/bin/java" -Djava.security.manager$v -version 2>&1)"; rc=$?
  label="-Djava.security.manager${v:-  (bare)}"
  if [ "$rc" -eq 0 ]; then
    printf '  %-46s exit=0  starts
' "$label"; ok_values+=("${v:-bare}")
  else
    printf '  %-46s exit=%s  %s
' "$label" "$rc" "$(echo "$out" | head -1)"; fatal_values+=("${v:-bare}")
  fi
done
echo "  fatal: ${fatal_values[*]}"
echo "  starts: ${ok_values[*]}"

ok=1
[ "$jdk8_exit" -eq 0 ] || { echo "MISMATCH: JDK 8 should start with the bare flag"; ok=0; }
[ "$jdk25_exit" -ne 0 ] || { echo "MISMATCH: JDK 25 should refuse the bare flag"; ok=0; }
echo "$jdk25_out" | grep -q "initialization of VM" || { echo "MISMATCH: expected a VM-init error on JDK 25"; ok=0; }
# Exactly one value should survive, and it should be disallow.
[ "${#ok_values[@]}" -eq 1 ] && [ "${ok_values[0]}" = "=disallow" ] || {
  echo "MISMATCH: expected only =disallow to start; got: ${ok_values[*]}"; ok=0; }
[ "${#fatal_values[@]}" -eq 4 ] || { echo "MISMATCH: expected 4 fatal values, got ${#fatal_values[@]}"; ok=0; }

echo ""
if [ "$ok" = "1" ]; then
  echo "REPRODUCED: JDK 8 starts fine with -Djava.security.manager; JDK 25 refuses to start the VM at all. The refusal is about the VALUE, not the property: bare, =allow, =default and a custom class name are all VM-init-fatal, while =disallow starts normally because it asks for the JDK 24 default. So a flag audit should remove the first four and can leave =disallow alone."
  exit 0
else
  echo "DID NOT REPRODUCE the documented behaviour -- investigate."
  exit 1
fi
