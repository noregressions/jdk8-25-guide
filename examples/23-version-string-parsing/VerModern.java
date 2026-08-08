// The fix: Runtime.version() and Runtime.Version.feature() give a structured,
// version-scheme-independent answer. This class DOES NOT COMPILE on JDK 8 --
// Runtime.version() is JDK 9+ (JEP 223) -- which is itself part of the point:
// code written to be portable across 8 and 25 either needs a runtime check with
// reflection, or (more realistically) just drops JDK 8 support and uses this
// directly once JDK 9+ is the floor.
public class VerModern {
    public static void main(String[] args) {
        System.out.println("Runtime.version() = " + Runtime.version());
        System.out.println("Runtime.version().feature() = " + Runtime.version().feature());
    }
}
