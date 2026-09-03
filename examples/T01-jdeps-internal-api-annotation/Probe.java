// Three JDK-internal references, deliberately chosen to land in DIFFERENT modules.
// Compiled once under JDK 8 (where all three were ordinary, compilable API), then
// both scanned with jdeps and RUN, unmodified, under JDK 25.
//
// The point: "JDK internal API" is not one category. jdeps says which module each
// one belongs to, and the module decides whether the call still works.
import sun.misc.Unsafe;
import sun.reflect.ReflectionFactory;
import sun.security.x509.X509CertImpl;

public class Probe {
    // Fields alone are enough to put all three in the constant pool, which is
    // what jdeps reads. main() then exercises two of them for real.
    Unsafe a;
    ReflectionFactory b;
    X509CertImpl c;

    public static void main(String[] args) {
        try {
            ReflectionFactory rf = ReflectionFactory.getReflectionFactory();
            System.out.println("ReflectionFactory: OK (" + (rf != null) + ")");
        } catch (Throwable t) {
            System.out.println("ReflectionFactory: " + t.getClass().getName());
        }
        try {
            System.out.println("X509CertImpl: OK (" + X509CertImpl.class.getName() + ")");
        } catch (Throwable t) {
            System.out.println("X509CertImpl: " + t.getClass().getName());
        }
    }
}
