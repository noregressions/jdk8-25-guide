#!/usr/bin/env bash
# 15 -- RMI Activation (JDK 17, JEP 407) and Pack200 (JDK 14, JEP 367) removed.
# Two independent, long-unmaintained corners of the platform, checked together
# since neither has a direct replacement API -- the fix for both is "remove the
# dependency," not "migrate to X."
set -uo pipefail
: "${JDK8_HOME:?set JDK8_HOME}" "${JDK25_HOME:?set JDK25_HOME}"
cd "$(dirname "$0")"
mkdir -p out
"$JDK8_HOME/bin/javac" -d out RmiAct.java Pack.java

echo "java.rmi.activation.ActivationSystem:"
echo "  JDK 8:"
rmi8_out="$("$JDK8_HOME/bin/java" -cp out RmiAct 2>&1)"; rmi8_exit=$?
echo "$rmi8_out" | sed 's/^/    /'; echo "    exit=$rmi8_exit"
echo "  JDK 25 (same .class, no recompile):"
rmi25_out="$("$JDK25_HOME/bin/java" -cp out RmiAct 2>&1)"; rmi25_exit=$?
echo "$rmi25_out" | sed 's/^/    /'; echo "    exit=$rmi25_exit"

echo "java.util.jar.Pack200:"
echo "  JDK 8:"
pack8_out="$("$JDK8_HOME/bin/java" -cp out Pack 2>&1)"; pack8_exit=$?
echo "$pack8_out" | sed 's/^/    /'; echo "    exit=$pack8_exit"
echo "  JDK 25 (same .class, no recompile):"
pack25_out="$("$JDK25_HOME/bin/java" -cp out Pack 2>&1)"; pack25_exit=$?
echo "$pack25_out" | sed 's/^/    /'; echo "    exit=$pack25_exit"

rm -rf out

ok=true
[ "$rmi8_exit" -eq 0 ] || ok=false
[ "$rmi25_exit" -ne 0 ] || ok=false
echo "$rmi25_out" | grep -q "NoClassDefFoundError" || ok=false
[ "$pack8_exit" -eq 0 ] || ok=false
[ "$pack25_exit" -ne 0 ] || ok=false
echo "$pack25_out" | grep -q "NoClassDefFoundError" || ok=false

# --- The scoping claim: plain RMI survives ----------------------------------------
# Chapter 3.15's most useful sentence is that ONLY the activation subsystem went --
# java.rmi.Remote, registries and exported objects all still work on JDK 25. That is
# the difference between rewiring some activation glue and rewriting an RMI layer, so
# it is worth proving rather than asserting. Full round trip on a private port.
echo ""
echo "Plain RMI (no activation) on JDK 25 -- export, register, look up, call:"
rmi_dir="$(mktemp -d)"
cat > "$rmi_dir/Svc.java" <<'JAVA'
import java.rmi.*;
public interface Svc extends Remote { String ping() throws RemoteException; }
JAVA
cat > "$rmi_dir/SvcMain.java" <<'JAVA'
import java.rmi.registry.*; import java.rmi.server.*;
public class SvcMain implements Svc {
    public String ping() { return "pong"; }
    public static void main(String[] args) throws Exception {
        SvcMain impl = new SvcMain();
        Svc stub = (Svc) UnicastRemoteObject.exportObject(impl, 0);
        Registry reg = LocateRegistry.createRegistry(31099);
        reg.rebind("svc", stub);
        Svc client = (Svc) LocateRegistry.getRegistry(31099).lookup("svc");
        System.out.println("plain RMI round trip = " + client.ping());
        UnicastRemoteObject.unexportObject(impl, true);
        UnicastRemoteObject.unexportObject(reg, true);
    }
}
JAVA
"$JDK25_HOME/bin/javac" -d "$rmi_dir/out" "$rmi_dir/Svc.java" "$rmi_dir/SvcMain.java" 2>/dev/null
rmi_out="$("$JDK25_HOME/bin/java" -cp "$rmi_dir/out" SvcMain 2>&1)"; rmi_exit=$?
echo "$rmi_out" | sed 's/^/  /'
echo "  exit=$rmi_exit"
rm -rf "$rmi_dir"

if [ "$rmi_exit" -ne 0 ] || ! echo "$rmi_out" | grep -q "plain RMI round trip = pong"; then
  echo "MISMATCH: plain RMI was expected to still work on JDK 25 -- only the activation subsystem was removed."
  exit 1
fi

if $ok; then
  echo "REPRODUCED: both java.rmi.activation and java.util.jar.Pack200 classes run fine on JDK 8, NoClassDefFoundError on JDK 25 -- the JDK no longer ships either."
  echo "ALSO REPRODUCED: the removal is precisely scoped. Plain RMI still works on JDK 25 -- exporting an object, creating a registry, binding, looking up and calling all succeed. A hit on java.rmi.activation means rewiring the activation glue, not rewriting the RMI layer."
  exit 0
else
  echo "DID NOT REPRODUCE the documented difference -- investigate."
  exit 1
fi
